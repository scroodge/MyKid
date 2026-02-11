import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';

import '../data/child.dart';
import '../data/local/scanned_photos_cache.dart';
import 'face_recognition_service.dart';

/// Result of a photo that matches a child (suggestion to create journal entry).
/// Source: local (photo_manager) or immich (Immich People API).
class PhotoSuggestion {
  PhotoSuggestion({
    required this.child,
    required this.date,
    this.assetId,
    this.immichAssetId,
    this.thumbnailBytes,
    this.thumbnailUrl,
  }) : assert(
          assetId != null || immichAssetId != null,
          'Either assetId or immichAssetId must be set',
        );

  /// Local photo_manager asset ID (when source is local scan).
  final String? assetId;
  /// Immich asset ID (when source is Immich People API).
  final String? immichAssetId;
  final Child child;
  final DateTime date;
  final Uint8List? thumbnailBytes;
  /// Immich thumbnail URL (with API key) when source is Immich.
  final String? thumbnailUrl;

  bool get isFromImmich => immichAssetId != null;
}

/// Scans the photo library for photos matching registered children's faces.
class PhotoLibraryScanner {
  PhotoLibraryScanner() {
    _faceService = FaceRecognitionService();
  }

  late final FaceRecognitionService _faceService;

  /// Request photo library permission. Returns true if granted.
  Future<bool> requestPermission() async {
    final state = await PhotoManager.requestPermissionExtend();
    return state.isAuth || state.hasAccess;
  }

  bool _cancelled = false;

  void cancelScan() {
    _cancelled = true;
  }

  /// Scans the library for photos matching children. Calls [onProgress] with
  /// (scanned, total). Calls [onSuggestionFound] when a match is found.
  /// Stops after [maxPhotos] or when [cancelScan] is called.
  Future<List<PhotoSuggestion>> scan({
    required List<Child> children,
    required List<String> childIdsWithEmbeddings,
    void Function(int scanned, int total)? onProgress,
    void Function(PhotoSuggestion suggestion)? onSuggestionFound,
    int batchSize = 20,
    int maxPhotos = 500,
  }) async {
    _cancelled = false;
    if (children.isEmpty || childIdsWithEmbeddings.isEmpty) return [];

    // Earliest relevant date: min(dateOfBirth) among children we're matching
    DateTime? minDate;
    for (final c in children) {
      if (!childIdsWithEmbeddings.contains(c.id)) continue;
      final dob = c.dateOfBirth;
      if (dob != null) {
        minDate = minDate == null ? dob : (dob.isBefore(minDate) ? dob : minDate);
      }
    }

    final hasPermission = await requestPermission();
    if (!hasPermission) return [];

    List<AssetPathEntity> paths;
    try {
      paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: true,
        onlyAll: true,
      );
    } catch (_) {
      return [];
    }
    if (paths.isEmpty) return [];

    final allPath = paths.first;
    var total = 0;
    try {
      total = await allPath.assetCountAsync;
    } catch (_) {
      return [];
    }
    if (total == 0) return [];

    total = total > maxPhotos ? maxPhotos : total;
    final suggestions = <PhotoSuggestion>[];
    final scannedIds = ScannedPhotosCache.getScannedIds();
    var processed = 0;
    var page = 0;

    while (true) {
      List<AssetEntity> assets;
      try {
        assets = await allPath.getAssetListPaged(page: page, size: batchSize);
      } catch (_) {
        break;
      }
      if (assets.isEmpty) break;

      var shouldStop = false;
      for (final asset in assets) {
        if (_cancelled || processed >= maxPhotos) {
          shouldStop = true;
          break;
        }
        if (scannedIds.contains(asset.id)) {
          processed++;
          onProgress?.call(processed, total);
          continue;
        }
        if (minDate != null && asset.createDateTime.isBefore(minDate)) {
          // Photos are typically newest-first; older photos won't match
          shouldStop = true;
          break;
        }

        Uint8List? bytes;
        try {
          bytes = await asset.thumbnailDataWithSize(
            const ThumbnailSize.square(512),
          );
        } catch (_) {}
        if (bytes == null || bytes.isEmpty) {
          processed++;
          onProgress?.call(processed, total);
          continue;
        }

        final detected = await _faceService.detectFaces(bytes);
        for (final d in detected) {
          for (var i = 0; i < children.length; i++) {
            final child = children[i];
            if (!childIdsWithEmbeddings.contains(child.id)) continue;
            if (_faceService.matchToChild(d.embedding, child.id)) {
              final s = PhotoSuggestion(
                assetId: asset.id,
                child: child,
                date: asset.createDateTime,
                thumbnailBytes: bytes,
              );
              suggestions.add(s);
              onSuggestionFound?.call(s);
              break;
            }
          }
        }

        await ScannedPhotosCache.addScannedIds([asset.id]);
        processed++;
        onProgress?.call(processed, total);
      }

      page++;
      if (assets.length < batchSize || _cancelled || shouldStop) break;
    }

    if (!_cancelled) ScannedPhotosCache.setLastScan(DateTime.now());
    return suggestions;
  }

  Future<void> dispose() async {
    await _faceService.dispose();
  }
}
