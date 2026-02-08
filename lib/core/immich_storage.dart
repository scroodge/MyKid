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

  Future<String?> getServerUrl() => _storage.read(key: _kImmichUrlKey);
  Future<void> setServerUrl(String? value) async {
    if (value == null) {
      await _storage.delete(key: _kImmichUrlKey);
    } else {
      await _storage.write(key: _kImmichUrlKey, value: value.trim());
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
