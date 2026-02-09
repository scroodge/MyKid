import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kSupabaseUrlKey = 'supabase_url';
const _kSupabaseAnonKeyKey = 'supabase_anon_key';

/// Persist Supabase URL and anon key securely. Used for user-provided credentials.
class SupabaseStorage {
  SupabaseStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  final FlutterSecureStorage _storage;

  Future<String?> getUrl() => _storage.read(key: _kSupabaseUrlKey);
  Future<void> setUrl(String? value) async {
    if (value == null) {
      await _storage.delete(key: _kSupabaseUrlKey);
    } else {
      await _storage.write(key: _kSupabaseUrlKey, value: value.trim());
    }
  }

  Future<String?> getAnonKey() => _storage.read(key: _kSupabaseAnonKeyKey);
  Future<void> setAnonKey(String? value) async {
    if (value == null) {
      await _storage.delete(key: _kSupabaseAnonKeyKey);
    } else {
      await _storage.write(key: _kSupabaseAnonKeyKey, value: value.trim());
    }
  }

  Future<bool> hasCredentials() async {
    final url = await getUrl();
    final key = await getAnonKey();
    return (url ?? '').trim().isNotEmpty && (key ?? '').trim().isNotEmpty;
  }

  Future<void> clear() async {
    await _storage.delete(key: _kSupabaseUrlKey);
    await _storage.delete(key: _kSupabaseAnonKeyKey);
  }
}
