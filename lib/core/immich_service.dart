import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../data/child.dart';
import 'immich_client.dart';
import 'immich_storage.dart';

/// Builds ImmichClient from stored credentials. Returns null if not configured.
class ImmichService {
  ImmichService([ImmichStorage? storage]) : _storage = storage ?? ImmichStorage();

  final ImmichStorage _storage;

  Future<ImmichClient?> getClient() async {
    final url = await _storage.getServerUrl();
    final key = await _storage.getApiKey();
    if (url == null || url.trim().isEmpty || key == null || key.trim().isEmpty) {
      return null;
    }
    final baseUrl = url.endsWith('/') ? url.trim().substring(0, url.trim().length - 1) : url.trim();
    return ImmichClient(baseUrl: baseUrl, apiKey: key);
  }

  static const _deviceId = 'mykid-app';

  /// Upload from bytes. Returns (id, null) on success or (null, errorMessage) on failure.
  Future<({String? id, String? error})> uploadFromBytes(
    Uint8List bytes,
    String filename, {
    DateTime? fileCreatedAt,
    DateTime? fileModifiedAt,
  }) async {
    final client = await getClient();
    if (client == null) return (id: null, error: 'Immich not configured');
    final now = DateTime.now();
    final created = fileCreatedAt ?? now;
    final modified = fileModifiedAt ?? now;
    final deviceAssetId = '${filename}_${modified.millisecondsSinceEpoch}';
    return client.uploadAsset(
      bytes: bytes,
      filename: filename,
      deviceId: _deviceId,
      deviceAssetId: deviceAssetId,
      fileCreatedAt: created,
      fileModifiedAt: modified,
    );
  }

  /// Pick image from [xFile] (e.g. from ImagePicker), upload to Immich.
  Future<({String? id, String? error})> uploadFromXFile(XFile xFile) async {
    final bytes = await xFile.readAsBytes();
    final name = xFile.name;
    if (name.isEmpty) {
      final ext = xFile.mimeType?.split('/').last ?? 'jpg';
      return uploadFromBytes(bytes, 'image.$ext');
    }
    return uploadFromBytes(bytes, name);
  }

  /// Ensure child has an Immich album (create if needed), add [assetId] to it.
  /// Call [onAlbumCreated] with the new album id when an album is created (so caller can save to child).
  Future<bool> addAssetToChildAlbum(
    Child child,
    String assetId, {
    void Function(String albumId)? onAlbumCreated,
  }) async {
    final client = await getClient();
    if (client == null) return false;
    String? albumId = child.immichAlbumId;
    if (albumId == null || albumId.isEmpty) {
      albumId = await client.createAlbum('MyKid: ${child.name}', assetIds: [assetId]);
      if (albumId == null) return false;
      onAlbumCreated?.call(albumId);
    } else {
      final ok = await client.addAssetsToAlbum(albumId, [assetId]);
      if (!ok) return false;
    }
    return true;
  }
}
