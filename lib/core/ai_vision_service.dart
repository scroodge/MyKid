import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import 'ai_provider_storage.dart';

class AiVisionService {
  AiVisionService([AiProviderStorage? storage]) : _storage = storage ?? AiProviderStorage();

  final AiProviderStorage _storage;

  /// Check if any AI provider is configured
  Future<bool> isConfigured() async {
    final selectedProvider = await _storage.getSelectedProvider();
    if (selectedProvider == null) return false;
    
    switch (selectedProvider) {
      case 'openai':
        final key = await _storage.getOpenAiKey();
        return key != null && key.trim().isNotEmpty;
      case 'gemini':
        final key = await _storage.getGeminiKey();
        return key != null && key.trim().isNotEmpty;
      case 'claude':
        final key = await _storage.getClaudeKey();
        return key != null && key.trim().isNotEmpty;
      case 'deepseek':
        final key = await _storage.getDeepSeekKey();
        return key != null && key.trim().isNotEmpty;
      default:
        return false;
    }
  }

  /// Analyze image and generate description. Returns generated text or error message.
  Future<({String? text, String? error})> analyzeImage(
    Uint8List imageBytes, {
    String? provider,
  }) async {
    // Determine which provider to use
    final selectedProvider = provider ?? await _storage.getSelectedProvider();
    if (selectedProvider == null) {
      return (text: null, error: 'No AI provider selected');
    }

    // Get API key for selected provider
    String? apiKey;
    switch (selectedProvider) {
      case 'openai':
        apiKey = await _storage.getOpenAiKey();
        break;
      case 'gemini':
        apiKey = await _storage.getGeminiKey();
        break;
      case 'claude':
        apiKey = await _storage.getClaudeKey();
        break;
      case 'deepseek':
        apiKey = await _storage.getDeepSeekKey();
        break;
      default:
        return (text: null, error: 'Unknown provider: $selectedProvider');
    }

    if (apiKey == null || apiKey.trim().isEmpty) {
      return (text: null, error: 'API key not configured for $selectedProvider');
    }

    // Convert image to base64
    final base64Image = base64Encode(imageBytes);
    
    // Call appropriate provider
    switch (selectedProvider) {
      case 'openai':
        return await _callOpenAiVision(apiKey, base64Image);
      case 'gemini':
        return await _callGeminiVision(apiKey, base64Image);
      case 'claude':
        return await _callClaudeVision(apiKey, base64Image);
      case 'deepseek':
        return await _callDeepSeekVision(apiKey, base64Image);
      default:
        return (text: null, error: 'Unknown provider: $selectedProvider');
    }
  }

  Future<({String? text, String? error})> _callOpenAiVision(String apiKey, String base64Image) async {
    try {
      const url = 'https://api.openai.com/v1/chat/completions';
      final prompt = 'This is a photo from a family journal app for documenting a child\'s life. As a parent, I want to create a warm, personal description of this moment for my child\'s memory book. Please describe what you see in the photo - what the child is doing, the setting, and any notable details. Write in Russian, keep it warm and positive, 2-3 sentences.';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful assistant that helps parents create journal entries for their children. You describe photos in a warm, positive, and age-appropriate manner.',
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': prompt,
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  },
                },
              ],
            },
          ],
          'max_tokens': 300,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final choice = choices[0] as Map<String, dynamic>?;
          
          // Check finish_reason
          final finishReason = choice?['finish_reason'] as String?;
          if (finishReason == 'content_filter') {
            return (text: null, error: 'OpenAI blocked the response due to content filters. Try using a different provider.');
          }
          
          final message = choice?['message'] as Map<String, dynamic>?;
          final content = message?['content'] as String?;
          if (content != null && content.trim().isNotEmpty) {
            // Check if response is a refusal
            final lowerContent = content.toLowerCase();
            if (lowerContent.contains('sorry') && (lowerContent.contains('can\'t help') || lowerContent.contains('cannot help'))) {
              return (text: null, error: 'AI provider refused to analyze the image. This may happen with certain content. Try a different provider or describe the photo manually.');
            }
            return (text: content.trim(), error: null);
          }
        }
        return (text: null, error: 'Empty response from OpenAI');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage = errorData?['error']?['message'] as String? ?? response.body;
        return (text: null, error: 'OpenAI API error: $errorMessage');
      }
    } catch (e) {
      return (text: null, error: 'Failed to call OpenAI: $e');
    }
  }

  Future<({String? text, String? error})> _callGeminiVision(String apiKey, String base64Image) async {
    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');
      final prompt = 'Это фото из семейного приложения для ведения дневника жизни ребенка. Как родитель, я хочу создать теплое, личное описание этого момента для дневника моего ребенка. Опиши, что ты видишь на фото - что делает ребенок, обстановку и любые заметные детали. Напиши на русском языке, будь теплым и позитивным, 2-3 предложения.';

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'You are a helpful assistant that helps parents create journal entries for their children. You describe photos in a warm, positive, and age-appropriate manner.',
                },
                {'text': prompt},
                {
                  'inline_data': {
                    'mime_type': 'image/jpeg',
                    'data': base64Image,
                  },
                },
              ],
            },
          ],
          'generationConfig': {
            'maxOutputTokens': 300,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_NONE',
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_NONE',
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_ONLY_HIGH',
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_ONLY_HIGH',
            },
          ],
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Check for safety blocks
        final promptFeedback = data['promptFeedback'] as Map<String, dynamic>?;
        if (promptFeedback != null) {
          final blockReason = promptFeedback['blockReason'] as String?;
          if (blockReason != null) {
            return (text: null, error: 'Gemini blocked the request: $blockReason. Try adjusting safety settings or use a different provider.');
          }
        }
        
        final candidates = data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final candidate = candidates[0] as Map<String, dynamic>?;
          
          // Check if candidate was blocked
          final finishReason = candidate?['finishReason'] as String?;
          if (finishReason == 'SAFETY' || finishReason == 'RECITATION') {
            return (text: null, error: 'Gemini blocked the response due to safety filters. Try using a different provider or adjusting settings.');
          }
          
          final content = candidate?['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            if (text != null && text.trim().isNotEmpty) {
              // Check if response is a refusal
              final lowerText = text.toLowerCase();
              if (lowerText.contains('извини') && lowerText.contains('не могу помочь')) {
                return (text: null, error: 'AI provider refused to analyze the image. This may happen with certain content. Try a different provider or describe the photo manually.');
              }
              return (text: text.trim(), error: null);
            }
          }
        }
        return (text: null, error: 'Empty response from Gemini');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage = errorData?['error']?['message'] as String? ?? response.body;
        return (text: null, error: 'Gemini API error: $errorMessage');
      }
    } catch (e) {
      return (text: null, error: 'Failed to call Gemini: $e');
    }
  }

  Future<({String? text, String? error})> _callClaudeVision(String apiKey, String base64Image) async {
    try {
      const url = 'https://api.anthropic.com/v1/messages';
      final prompt = 'Это фото из семейного приложения для ведения дневника жизни ребенка. Как родитель, я хочу создать теплое, личное описание этого момента для дневника моего ребенка. Опиши, что ты видишь на фото - что делает ребенок, обстановку и любые заметные детали. Напиши на русском языке, будь теплым и позитивным, 2-3 предложения.';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'claude-3-5-sonnet-20241022',
          'max_tokens': 300,
          'system': 'You are a helpful assistant that helps parents create journal entries for their children. You describe photos in a warm, positive, and age-appropriate manner.',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': 'image/jpeg',
                    'data': base64Image,
                  },
                },
                {
                  'type': 'text',
                  'text': prompt,
                },
              ],
            },
          ],
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = data['content'] as List?;
        if (content != null && content.isNotEmpty) {
          final textBlock = content[0] as Map<String, dynamic>?;
          final text = textBlock?['text'] as String?;
          if (text != null && text.trim().isNotEmpty) {
            // Check if response is a refusal
            final lowerText = text.toLowerCase();
            if (lowerText.contains('извини') && (lowerText.contains('не могу помочь') || lowerText.contains('не могу'))) {
              return (text: null, error: 'AI provider refused to analyze the image. This may happen with certain content. Try a different provider or describe the photo manually.');
            }
            return (text: text.trim(), error: null);
          }
        }
        
        // Check for stop_reason indicating refusal
        final stopReason = data['stop_reason'] as String?;
        if (stopReason == 'content_filtered') {
          return (text: null, error: 'Claude blocked the response due to content filters. Try using a different provider.');
        }
        
        return (text: null, error: 'Empty response from Claude');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage = errorData?['error']?['message'] as String? ?? errorData?['error']?['type'] as String? ?? response.body;
        return (text: null, error: 'Claude API error: $errorMessage');
      }
    } catch (e) {
      return (text: null, error: 'Failed to call Claude: $e');
    }
  }

  /// DeepSeek API is OpenAI-compatible; supports vision via image_url in content.
  Future<({String? text, String? error})> _callDeepSeekVision(String apiKey, String base64Image) async {
    try {
      const url = 'https://api.deepseek.com/v1/chat/completions';
      final prompt = 'Это фото из семейного приложения для ведения дневника жизни ребенка. Как родитель, я хочу создать теплое, личное описание этого момента для дневника моего ребенка. Опиши, что ты видишь на фото - что делает ребенок, обстановку и любые заметные детали. Напиши на русском языке, будь теплым и позитивным, 2-3 предложения.';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful assistant that helps parents create journal entries for their children. You describe photos in a warm, positive, and age-appropriate manner.',
            },
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
                },
              ],
            },
          ],
          'max_tokens': 300,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final choice = choices[0] as Map<String, dynamic>?;
          final finishReason = choice?['finish_reason'] as String?;
          if (finishReason == 'content_filter') {
            return (text: null, error: 'DeepSeek blocked the response due to content filters. Try using a different provider.');
          }
          final message = choice?['message'] as Map<String, dynamic>?;
          final content = message?['content'] as String?;
          if (content != null && content.trim().isNotEmpty) {
            final lowerContent = content.toLowerCase();
            if (lowerContent.contains('извини') && (lowerContent.contains('не могу помочь') || lowerContent.contains('не могу'))) {
              return (text: null, error: 'AI provider refused to analyze the image. This may happen with certain content. Try a different provider or describe the photo manually.');
            }
            return (text: content.trim(), error: null);
          }
        }
        return (text: null, error: 'Empty response from DeepSeek');
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
        final errorMessage = errorData?['error']?['message'] as String? ?? response.body;
        return (text: null, error: 'DeepSeek API error: $errorMessage');
      }
    } catch (e) {
      return (text: null, error: 'Failed to call DeepSeek: $e');
    }
  }

  /// Test connection to a provider with a simple request
  Future<({bool success, String? error})> testConnection(String provider) async {
    String? apiKey;
    switch (provider) {
      case 'openai':
        apiKey = await _storage.getOpenAiKey();
        break;
      case 'gemini':
        apiKey = await _storage.getGeminiKey();
        break;
      case 'claude':
        apiKey = await _storage.getClaudeKey();
        break;
      case 'deepseek':
        apiKey = await _storage.getDeepSeekKey();
        break;
      default:
        return (success: false, error: 'Unknown provider');
    }

    if (apiKey == null || apiKey.trim().isEmpty) {
      return (success: false, error: 'API key not configured');
    }

    // Create a minimal test image (1x1 pixel PNG)
    final testImageBytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
    );

    final result = await analyzeImage(testImageBytes, provider: provider);
    if (result.text != null) {
      return (success: true, error: null);
    } else {
      return (success: false, error: result.error ?? 'Connection failed');
    }
  }
}
