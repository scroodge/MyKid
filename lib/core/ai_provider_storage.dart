import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kOpenAiKeyKey = 'ai_provider_openai_key';
const _kGeminiKeyKey = 'ai_provider_gemini_key';
const _kClaudeKeyKey = 'ai_provider_claude_key';
const _kSelectedProviderKey = 'ai_provider_selected';

/// Persist AI provider API keys securely.
class AiProviderStorage {
  AiProviderStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  final FlutterSecureStorage _storage;

  Future<String?> getOpenAiKey() => _storage.read(key: _kOpenAiKeyKey);
  Future<void> setOpenAiKey(String? value) async {
    if (value == null) {
      await _storage.delete(key: _kOpenAiKeyKey);
    } else {
      await _storage.write(key: _kOpenAiKeyKey, value: value.trim());
    }
  }

  Future<String?> getGeminiKey() => _storage.read(key: _kGeminiKeyKey);
  Future<void> setGeminiKey(String? value) async {
    if (value == null) {
      await _storage.delete(key: _kGeminiKeyKey);
    } else {
      await _storage.write(key: _kGeminiKeyKey, value: value.trim());
    }
  }

  Future<String?> getClaudeKey() => _storage.read(key: _kClaudeKeyKey);
  Future<void> setClaudeKey(String? value) async {
    if (value == null) {
      await _storage.delete(key: _kClaudeKeyKey);
    } else {
      await _storage.write(key: _kClaudeKeyKey, value: value.trim());
    }
  }

  Future<String?> getSelectedProvider() => _storage.read(key: _kSelectedProviderKey);
  Future<void> setSelectedProvider(String? value) async {
    if (value == null) {
      await _storage.delete(key: _kSelectedProviderKey);
    } else {
      await _storage.write(key: _kSelectedProviderKey, value: value.trim());
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _kOpenAiKeyKey);
    await _storage.delete(key: _kGeminiKeyKey);
    await _storage.delete(key: _kClaudeKeyKey);
    await _storage.delete(key: _kSelectedProviderKey);
  }
}
