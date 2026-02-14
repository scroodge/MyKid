import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kSupabaseUrlKey = 'supabase_url';
const _kSupabasePublishableKeyKey = 'supabase_publishable_key';
const _kSupabaseAnonKeyKeyLegacy = 'supabase_anon_key'; // migration from old name
const _kClearedForCustomKey = 'supabase_cleared_for_custom';

/// Persist Supabase URL and publishable key securely. Used for user-provided credentials.
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

  Future<String?> getPublishableKey() async {
    var value = await _storage.read(key: _kSupabasePublishableKeyKey);
    if (value == null || value.isEmpty) {
      value = await _storage.read(key: _kSupabaseAnonKeyKeyLegacy);
      if (value != null && value.isNotEmpty) {
        await _storage.write(key: _kSupabasePublishableKeyKey, value: value);
        await _storage.delete(key: _kSupabaseAnonKeyKeyLegacy);
      }
    }
    return value;
  }
  Future<void> setPublishableKey(String? value) async {
    if (value == null) {
      await _storage.delete(key: _kSupabasePublishableKeyKey);
    } else {
      await _storage.write(key: _kSupabasePublishableKeyKey, value: value.trim());
    }
  }

  Future<bool> hasCredentials() async {
    final url = await getUrl();
    final key = await getPublishableKey();
    return (url ?? '').trim().isNotEmpty && (key ?? '').trim().isNotEmpty;
  }

  Future<void> clear() async {
    await _storage.delete(key: _kSupabaseUrlKey);
    await _storage.delete(key: _kSupabasePublishableKeyKey);
    await _storage.delete(key: _kSupabaseAnonKeyKeyLegacy);
  }

  /// When user taps "Change Supabase", we clear and set this flag.
  /// On next app load, config uses placeholder (not default) so onboarding is shown.
  Future<void> clearForCustomBackend() async {
    await clear();
    await _storage.write(key: _kClearedForCustomKey, value: '1');
  }

  Future<bool> wasClearedForCustom() async {
    final v = await _storage.read(key: _kClearedForCustomKey);
    if (v == '1') {
      await _storage.delete(key: _kClearedForCustomKey);
      return true;
    }
    return false;
  }
}
