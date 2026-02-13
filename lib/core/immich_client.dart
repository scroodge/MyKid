import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Client for Immich API. Base URL should not end with slash.
/// Auth: x-api-key header.
/// Tested with Immich server 2.5.5.
class ImmichClient {
  ImmichClient({
    required this.baseUrl,
    required this.apiKey,
  });

  final String baseUrl;
  final String apiKey;

  Map<String, String> get _headers => {
        'x-api-key': apiKey,
        'Accept': 'application/json',
      };

  /// Check connectivity and auth (e.g. get server version).
  Future<bool> checkConnection() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/server/version'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Upload a single asset from bytes. Works on all platforms (including web).
  /// Returns (assetId, null) on success or (null, errorMessage) on failure.
  Future<({String? id, String? error})> uploadAsset({
    required Uint8List bytes,
    required String filename,
    required String deviceId,
    required String deviceAssetId,
    required DateTime fileCreatedAt,
    required DateTime fileModifiedAt,
  }) async {
    final uri = Uri.parse('$baseUrl/api/assets');
    final request = http.MultipartRequest('POST', uri);
    request.headers['x-api-key'] = apiKey;
    request.files.add(http.MultipartFile.fromBytes(
      'assetData',
      bytes,
      filename: filename,
    ));
    request.fields['deviceId'] = deviceId;
    request.fields['deviceAssetId'] = deviceAssetId;
    // Immich expects ISO 8601; use UTC for consistency
    request.fields['fileCreatedAt'] = fileCreatedAt.toUtc().toIso8601String();
    request.fields['fileModifiedAt'] = fileModifiedAt.toUtc().toIso8601String();
    request.fields['filename'] = filename;

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>?;
        return (id: body?['id'] as String?, error: null);
      }
      final msg = response.body.isNotEmpty ? response.body : (response.reasonPhrase ?? 'Unknown');
      return (id: null, error: '${response.statusCode}: $msg');
    } catch (e) {
      return (id: null, error: e.toString());
    }
  }

  /// Search assets (e.g. by date range). Returns list of asset objects.
  Future<List<ImmichAsset>> searchAssets({
    DateTime? takenAfter,
    DateTime? takenBefore,
    int page = 1,
    int size = 100,
  }) async {
    final body = <String, dynamic>{
      'page': page,
      'size': size,
    };
    if (takenAfter != null) body['takenAfter'] = takenAfter.toIso8601String();
    if (takenBefore != null) body['takenBefore'] = takenBefore.toIso8601String();

    final res = await http.post(
      Uri.parse('$baseUrl/api/assets/search'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>?;
    final items = data?['items'] as List<dynamic>? ?? [];
    final assets = data?['assets'] as Map<String, dynamic>?;
    final list = assets?['items'] as List<dynamic>? ?? items;
    return list
        .map((e) => ImmichAsset.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Create an album. Returns album id or null. Requires album.create permission.
  Future<String?> createAlbum(String albumName, {List<String>? assetIds}) async {
    final body = <String, dynamic>{'albumName': albumName};
    if (assetIds != null && assetIds.isNotEmpty) body['assetIds'] = assetIds;
    final res = await http.post(
      Uri.parse('$baseUrl/api/albums'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 201) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>?;
    return data?['id'] as String?;
  }

  /// Add assets to an album. Requires albumAsset.create permission.
  Future<bool> addAssetsToAlbum(String albumId, List<String> assetIds) async {
    if (assetIds.isEmpty) return true;
    final res = await http.put(
      Uri.parse('$baseUrl/api/albums/$albumId/assets'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'ids': assetIds}),
    );
    return res.statusCode == 200;
  }

  /// Remove assets from an album. Requires albumAsset.delete permission.
  Future<bool> removeAssetsFromAlbum(String albumId, List<String> assetIds) async {
    if (assetIds.isEmpty) return true;
    final res = await http.delete(
      Uri.parse('$baseUrl/api/albums/$albumId/assets'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'ids': assetIds}),
    );
    return res.statusCode == 200;
  }

  /// Thumbnail/preview URL for an asset. [size]: thumbnail (small), preview (larger), fullsize.
  /// Use with httpHeaders: {'x-api-key': apiKey}. For full-screen use downloadAsset (original) instead.
  String getAssetThumbnailUrl(String assetId, {String format = 'JPEG', String? size}) {
    final params = <String, String>{'format': format};
    if (size != null && size.isNotEmpty) params['size'] = size;
    final q = Uri(queryParameters: params);
    return '$baseUrl/api/assets/$assetId/thumbnail?${q.query}';
  }

  /// Full-size asset URL (for viewing, not thumbnail). Immich v2 API uses /original.
  String getAssetDownloadUrl(String assetId) {
    return '$baseUrl/api/assets/$assetId/original';
  }

  /// Full-size download URL with API key in query (for image widgets that may not send headers).
  String getAssetDownloadUrlWithKey(String assetId) {
    return '$baseUrl/api/assets/$assetId/original?key=${Uri.encodeComponent(apiKey)}';
  }

  /// Thumbnail/preview URL with API key in query. [size]: thumbnail, preview, fullsize.
  String getAssetThumbnailUrlWithKey(String assetId, {String format = 'JPEG', String? size}) {
    final params = <String, String>{'format': format, 'key': apiKey};
    if (size != null && size.isNotEmpty) params['size'] = size;
    final q = Uri(queryParameters: params);
    return '$baseUrl/api/assets/$assetId/thumbnail?${q.query}';
  }

  /// List all people (faces) recognized by Immich. Requires person.read permission.
  Future<List<ImmichPerson>> getAllPeople({int size = 100}) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/people').replace(
          queryParameters: {'size': size.toString()},
        ),
        headers: _headers,
      );
      if (res.statusCode != 200) return [];
      final data = jsonDecode(res.body) as Map<String, dynamic>?;
      final list = data?['people'] as List<dynamic>? ?? [];
      return list
          .map((e) => ImmichPerson.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Get assets for a person (photos where this person appears). Requires person.read and asset.read.
  Future<List<ImmichAsset>> getPersonAssets(String personId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/people/$personId/assets'),
        headers: _headers,
      );
      if (res.statusCode != 200) return [];
      final list = jsonDecode(res.body) as List<dynamic>? ?? [];
      return list
          .map((e) => ImmichAsset.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Download full asset bytes (for fullscreen view). Immich v2 API: GET /api/assets/:id/original.
  Future<List<int>?> downloadAsset(String assetId) async {
    final url = '$baseUrl/api/assets/$assetId/original';
    try {
      final res = await http.get(Uri.parse(url), headers: _headers);
      if (res.statusCode == 200) return res.bodyBytes;
      debugPrint('[Immich] downloadAsset $assetId → ${res.statusCode} ${res.reasonPhrase}');
      if (res.body.isNotEmpty) {
        final preview = res.body.length > 400 ? '${res.body.substring(0, 400)}...' : res.body;
        debugPrint('[Immich] response: $preview');
      }
      return null;
    } catch (e, st) {
      debugPrint('[Immich] downloadAsset $assetId error: $e');
      debugPrint('[Immich] $st');
      return null;
    }
  }
}

class ImmichPerson {
  ImmichPerson({required this.id, required this.name});

  final String id;
  final String name;

  factory ImmichPerson.fromJson(Map<String, dynamic> json) {
    return ImmichPerson(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class ImmichAsset {
  ImmichAsset({
    required this.id,
    required this.type,
    this.fileCreatedAt,
    this.localDateTime,
  });

  final String id;
  final String type; // IMAGE, VIDEO, etc.
  final DateTime? fileCreatedAt;
  final DateTime? localDateTime;

  factory ImmichAsset.fromJson(Map<String, dynamic> json) {
    DateTime? parse(String? s) {
      if (s == null) return null;
      return DateTime.tryParse(s);
    }
    return ImmichAsset(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'OTHER',
      fileCreatedAt: parse(json['fileCreatedAt'] as String?),
      localDateTime: parse(json['localDateTime'] as String?),
    );
  }
}
