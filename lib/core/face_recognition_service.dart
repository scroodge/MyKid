import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/local/face_embeddings_cache.dart';
import '../data/subscription_repository.dart';
import 'ai_provider_storage.dart';

/// Service for face detection and recognition. Uses ML Kit for detection and
/// geometric features or TFLite embeddings for matching.
/// AI Gateway for face embeddings is used only for Premium subscribers.
class FaceRecognitionService {
  FaceRecognitionService([
    AiProviderStorage? storage,
    SubscriptionRepository? subscriptionRepo,
  ])  : _storage = storage ?? AiProviderStorage(),
        _subscriptionRepo = subscriptionRepo ?? SubscriptionRepository() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableLandmarks: true,
        minFaceSize: 0.15,
      ),
    );
  }

  late final FaceDetector _faceDetector;
  final AiProviderStorage _storage;
  final SubscriptionRepository _subscriptionRepo;
  static const double _matchThreshold = 0.7;
  static const _uuid = Uuid();

  /// Detects faces in image bytes. Returns list of (bounding box, embedding).
  /// Uses Gateway embeddings if available, otherwise falls back to geometric embeddings.
  Future<List<({Rect rect, List<double> embedding})>> detectFaces(
    Uint8List bytes,
  ) async {
    if (bytes.isEmpty) return [];
    File? tempFile;
    try {
      final dir = await getTemporaryDirectory();
      tempFile = File(
        '${dir.path}/face_det_temp_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(bytes);
      final inputImage = InputImage.fromFilePath(tempFile.path);
      final faces = await _faceDetector.processImage(inputImage);
      if (faces.isEmpty) return [];

      // Strategy: use local resources first (geometric), then Gateway for better quality if available
      final useGateway = await _isGatewayAvailable();

      final results = <({Rect rect, List<double> embedding})>[];
      for (final face in faces) {
        // First, try geometric embedding (fast, offline, always available)
        var emb = _embeddingFromFace(face);
        
        // If Gateway is available, try to get better quality embedding
        // Gateway embeddings are more accurate but require internet
        if (useGateway && emb != null && emb.isNotEmpty) {
          try {
            final gatewayEmb = await _getGatewayEmbedding(bytes, face.boundingBox);
            if (gatewayEmb != null && gatewayEmb.isNotEmpty) {
              // Use Gateway embedding (better quality)
              emb = gatewayEmb;
            }
            // If Gateway failed, keep geometric embedding (fallback)
          } catch (_) {
            // Gateway error - keep geometric embedding
          }
        }
        
        if (emb != null && emb.isNotEmpty) {
          results.add((rect: face.boundingBox, embedding: emb));
        }
      }
      return results;
    } catch (_) {
      return [];
    } finally {
      try {
        if (tempFile != null && await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
    }
  }

  /// Builds a geometric embedding from ML Kit Face landmarks.
  /// Returns null if eyes/nose landmarks are missing (e.g. profile, low quality).
  List<double>? _embeddingFromFace(Face face) {
    final box = face.boundingBox;
    final w = box.width;
    final h = box.height;
    if (w <= 0 || h <= 0) return null;

    final landmarks = face.landmarks;
    final leftEye = landmarks[FaceLandmarkType.leftEye]?.position;
    final rightEye = landmarks[FaceLandmarkType.rightEye]?.position;
    final nose = landmarks[FaceLandmarkType.noseBase]?.position;
    final leftMouth = landmarks[FaceLandmarkType.leftMouth]?.position;
    final rightMouth = landmarks[FaceLandmarkType.rightMouth]?.position;

    if (leftEye != null && rightEye != null && nose != null) {
      // Normalized coords relative to bounding box. Always 10 values for consistent comparison.
      final lx = (leftEye.x - box.left) / w;
      final ly = (leftEye.y - box.top) / h;
      final rx = (rightEye.x - box.left) / w;
      final ry = (rightEye.y - box.top) / h;
      final nx = (nose.x - box.left) / w;
      final ny = (nose.y - box.top) / h;
      final lmX = leftMouth != null
          ? (leftMouth.x - box.left) / w
          : (lx + nx) / 2;
      final lmY = leftMouth != null
          ? (leftMouth.y - box.top) / h
          : ny + 0.15;
      final rmX = rightMouth != null
          ? (rightMouth.x - box.left) / w
          : (rx + nx) / 2;
      final rmY = rightMouth != null
          ? (rightMouth.y - box.top) / h
          : ny + 0.15;
      return [lx, ly, rx, ry, nx, ny, lmX, lmY, rmX, rmY];
    }
    return null;
  }

  /// Cosine similarity between two embeddings. Returns value in [0, 1].
  double compareFaces(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0;
    double dot = 0, na = 0, nb = 0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }
    if (na <= 0 || nb <= 0) return 0;
    final norm = math.sqrt(na) * math.sqrt(nb);
    if (norm <= 0) return 0;
    final sim = dot / norm;
    return (sim.clamp(-1.0, 1.0) + 1) / 2;
  }

  /// Checks if embedding matches any stored embedding for the child.
  bool matchToChild(List<double> embedding, String childId) {
    final stored = FaceEmbeddingsCache.getForChild(childId);
    if (stored.isEmpty) return false;
    for (final s in stored) {
      if (compareFaces(embedding, s.embedding) >= _matchThreshold) {
        return true;
      }
    }
    return false;
  }

  /// Generates and stores a new FaceEmbedding for the child from image bytes.
  Future<FaceEmbedding?> addReferencePhoto(
    String childId,
    String photoId,
    Uint8List bytes,
  ) async {
    final detected = await detectFaces(bytes);
    if (detected.isEmpty) return null;
    final best = detected.first;
    final fe = FaceEmbedding(
      id: _uuid.v4(),
      embedding: best.embedding,
      photoId: photoId,
      createdAt: DateTime.now(),
    );
    await FaceEmbeddingsCache.addForChild(childId, fe);
    return fe;
  }

  /// Checks if Gateway is available for face embeddings (Premium only).
  Future<bool> _isGatewayAvailable() async {
    final baseUrl = await _storage.getCustomAiBaseUrl();
    final token = await _storage.getCustomAiKey();
    if (baseUrl == null || baseUrl.trim().isEmpty ||
        token == null || token.trim().isEmpty) {
      return false;
    }
    final sub = await _subscriptionRepo.getMySubscription();
    return sub != null && sub.isActive && sub.isPremium;
  }

  /// Ensures base URL has http(s) scheme.
  static String _ensureUrlScheme(String url) {
    final t = url.trim().replaceAll(RegExp(r'/$'), '');
    if (t.isEmpty) return t;
    if (RegExp(r'^https?://', caseSensitive: false).hasMatch(t)) return t;
    return 'https://$t';
  }

  /// Crops face region from image bytes using bounding box.
  Uint8List? _cropFace(Uint8List imageBytes, Rect bbox) {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      // Expand bbox slightly for better context (10% padding)
      final padding = math.min(bbox.width, bbox.height) * 0.1;
      final x = math.max(0, (bbox.left - padding).round());
      final y = math.max(0, (bbox.top - padding).round());
      final w = math.min(image.width - x, (bbox.width + padding * 2).round());
      final h = math.min(image.height - y, (bbox.height + padding * 2).round());

      if (w <= 0 || h <= 0) return null;

      final cropped = img.copyCrop(image, x: x, y: y, width: w, height: h);
      return Uint8List.fromList(img.encodeJpg(cropped, quality: 90));
    } catch (_) {
      return null;
    }
  }

  /// Gets face embedding from Gateway API.
  Future<List<double>?> _getGatewayEmbedding(Uint8List imageBytes, Rect bbox) async {
    try {
      final baseUrl = await _storage.getCustomAiBaseUrl();
      final token = await _storage.getCustomAiKey();
      
      if (baseUrl == null || baseUrl.trim().isEmpty ||
          token == null || token.trim().isEmpty) {
        return null;
      }

      // Crop face region
      final faceCrop = _cropFace(imageBytes, bbox);
      if (faceCrop == null || faceCrop.isEmpty) return null;

      // Encode to base64
      final base64Image = base64Encode(faceCrop);

      // Build Gateway URL
      final gatewayUrl = _ensureUrlScheme(baseUrl);
      final url = Uri.parse('$gatewayUrl/v1/face-embedding');

      // Make request
      final response = await http.post(
        url,
        headers: {
          'X-Gateway-Token': token,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'image': base64Image}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final embedding = data['embedding'] as List?;
        if (embedding != null && embedding.isNotEmpty) {
          return embedding.map((e) => (e as num).toDouble()).toList();
        }
      } else if (response.statusCode == 404) {
        // No face detected - Gateway couldn't find face in crop
        // This is expected sometimes, fallback to geometric
        return null;
      }
      // Other errors: fallback to geometric embedding
      return null;
    } catch (_) {
      // Any error: fallback to geometric embedding
      return null;
    }
  }

  /// Disposes the face detector.
  Future<void> dispose() async {
    await _faceDetector.close();
  }
}
