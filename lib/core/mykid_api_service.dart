import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'legal_urls.dart';

/// Calls MyKid API (AI Gateway) for export and delete-account.
class MyKidApiService {
  MyKidApiService({String? baseUrl}) : _baseUrl = (baseUrl ?? LegalUrls.mykidApiUrl).replaceAll(RegExp(r'/$'), '');

  final String _baseUrl;

  bool get isConfigured => _baseUrl.isNotEmpty;

  Future<Map<String, dynamic>> exportData() async {
    if (!isConfigured) {
      throw MyKidApiException('Export not configured (MYKID_API_URL)');
    }
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;
    if (token == null) {
      throw MyKidApiException('Not authenticated');
    }

    final url = Uri.parse('$_baseUrl/mykid/export');
    final res = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(minutes: 2));

    if (res.statusCode != 200) {
      final body = res.body;
      String detail = 'Export failed';
      try {
        final json = _tryDecode(body);
        if (json != null && json['detail'] != null) {
          detail = json['detail'] is String ? json['detail'] as String : body;
        }
      } catch (_) {}
      throw MyKidApiException('$detail', statusCode: res.statusCode);
    }

    final json = _tryDecode(res.body);
    if (json == null) throw MyKidApiException('Invalid response');
    return json as Map<String, dynamic>;
  }

  Future<void> deleteAccount() async {
    if (!isConfigured) {
      throw MyKidApiException('Delete not configured (MYKID_API_URL)');
    }
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;
    if (token == null) {
      throw MyKidApiException('Not authenticated');
    }

    final url = Uri.parse('$_baseUrl/mykid/delete-account');
    final res = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) {
      final body = res.body;
      String detail = 'Delete failed';
      try {
        final json = _tryDecode(body);
        if (json != null && json['detail'] != null) {
          detail = json['detail'] is String ? json['detail'] as String : body;
        }
      } catch (_) {}
      throw MyKidApiException('$detail', statusCode: res.statusCode);
    }

    final json = _tryDecode(res.body);
    if (json != null && json['success'] == true) return;
    throw MyKidApiException('Delete failed');
  }

  dynamic _tryDecode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }
}

class MyKidApiException implements Exception {
  MyKidApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
