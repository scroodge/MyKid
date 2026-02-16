import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kImmichUrlKey = 'immich_server_url';
const _kImmichApiKeyKey = 'immich_api_key';

/// Persist Immich URL and API key securely.
class ImmichStorage {
  ImmichStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  final FlutterSecureStorage _storage;

  /// Normalize Immich URL: use scheme + host only (default port 443/80) so a wrong port never gets used.
  static String? normalizeServerUrl(String? url) {
    if (url == null) return null;
    final t = url.trim();
    if (t.isEmpty) return null;
    try {
      final uri = Uri.tryParse(t.contains('://') ? t : 'https://$t');
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) return t;
      final scheme = uri.scheme.toLowerCase() == 'http' ? 'http' : 'https';
      return '$scheme://${uri.host}';
    } catch (_) {
      return t;
    }
  }

  Future<String?> getServerUrl() async {
    final raw = await _storage.read(key: _kImmichUrlKey);
    return normalizeServerUrl(raw);
  }

  /// Raw value in storage (for debug). May contain wrong port; use getServerUrl() for actual URL.
  Future<String?> getServerUrlRaw() => _storage.read(key: _kImmichUrlKey);

  /// If stored URL has a port or extra chars, overwrite with normalized (scheme + host only).
  Future<void> ensureServerUrlNormalized() async {
    final raw = await _storage.read(key: _kImmichUrlKey);
    if (raw == null || raw.trim().isEmpty) return;
    final normalized = normalizeServerUrl(raw);
    if (normalized != null && raw.trim() != normalized) {
      await setServerUrl(normalized);
    }
  }

  Future<void> setServerUrl(String? value) async {
    if (value == null) {
      await _storage.delete(key: _kImmichUrlKey);
    } else {
      final normalized = normalizeServerUrl(value) ?? value.trim();
      await _storage.write(key: _kImmichUrlKey, value: normalized);
    }
  }

  Future<String?> getApiKey() => _storage.read(key: _kImmichApiKeyKey);
  Future<void> setApiKey(String? value) async {
    if (value == null) {
      await _storage.delete(key: _kImmichApiKeyKey);
    } else {
      await _storage.write(key: _kImmichApiKeyKey, value: value.trim());
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _kImmichUrlKey);
    await _storage.delete(key: _kImmichApiKeyKey);
  }
}
