import 'package:supabase_flutter/supabase_flutter.dart';

/// Calls Supabase Edge Functions for AI Gateway: create token, get usage.
class AiGatewayService {
  AiGatewayService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Create a new Gateway token for the current user. Returns the plain token (one-time).
  /// Requires authenticated session.
  Future<({String? token, String? error})> createToken() async {
    try {
      await _client.auth.refreshSession();
    } catch (_) {}

    final session = _client.auth.currentSession;
    if (session == null || session.accessToken.isEmpty) {
      return (token: null, error: 'Session expired. Sign in again.');
    }

    final res = await _client.functions.invoke(
      'create-gateway-token',
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );

    if (res.status != 200) {
      final err = res.data?['error'] as String? ?? res.data?.toString() ?? 'Failed to create token';
      return (token: null, error: err);
    }

    final token = res.data?['token'] as String?;
    if (token == null || token.isEmpty) {
      return (token: null, error: 'No token in response');
    }
    return (token: token, error: null);
  }

  /// Get usage stats for the current user.
  Future<({int? inputTokens, int? outputTokens, int? totalTokens, int? requestCount, Map<String, dynamic>? byDay, String? error})> getUsage({bool breakdown = false}) async {
    try {
      await _client.auth.refreshSession();
    } catch (_) {}

    final session = _client.auth.currentSession;
    if (session == null || session.accessToken.isEmpty) {
      return (inputTokens: null, outputTokens: null, totalTokens: null, requestCount: null, byDay: null, error: 'Session expired. Sign in again.');
    }

    final res = await _client.functions.invoke(
      'ai-gateway-usage',
      body: breakdown ? {'breakdown': true} : {},
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
    );

    if (res.status != 200) {
      final err = res.data?['error'] as String? ?? res.data?.toString() ?? 'Failed to fetch usage';
      return (inputTokens: null, outputTokens: null, totalTokens: null, requestCount: null, byDay: null, error: err);
    }

    final data = res.data as Map<String, dynamic>?;
    if (data == null) {
      return (inputTokens: null, outputTokens: null, totalTokens: null, requestCount: null, byDay: null, error: 'Empty response');
    }

    final inputTokens = data['input_tokens'] as int? ?? 0;
    final outputTokens = data['output_tokens'] as int? ?? 0;
    final totalTokens = data['total_tokens'] as int? ?? inputTokens + outputTokens;
    final requestCount = data['request_count'] as int? ?? 0;
    final byDay = data['by_day'] as Map<String, dynamic>?;

    return (
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalTokens: totalTokens,
      requestCount: requestCount,
      byDay: byDay,
      error: null,
    );
  }
}
