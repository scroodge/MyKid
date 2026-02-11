import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/local/face_embeddings_cache.dart';

/// Service for face detection and recognition. Uses ML Kit for detection and
/// geometric features or TFLite embeddings for matching.
class FaceRecognitionService {
  FaceRecognitionService() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableLandmarks: true,
        minFaceSize: 0.15,
      ),
    );
  }

  late final FaceDetector _faceDetector;
  static const double _matchThreshold = 0.7;
  static const _uuid = Uuid();

  /// Detects faces in image bytes. Returns list of (bounding box, embedding).
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

      final results = <({Rect rect, List<double> embedding})>[];
      for (final face in faces) {
        final emb = _embeddingFromFace(face);
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

  /// Disposes the face detector.
  Future<void> dispose() async {
    await _faceDetector.close();
  }
}
