import 'package:supabase_flutter/supabase_flutter.dart';

/// Fetches or saves household-level Immich config (API key in Vault) via Supabase RPC.
class HouseholdImmichService {
  HouseholdImmichService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Returns server_url and api_key for the household. Only call after user consent.
  /// Throws if not a member or RPC fails.
  Future<HouseholdImmichConfig> getHouseholdImmichConfig(String householdId) async {
    final res = await _client.rpc(
      'get_household_immich_config',
      params: {'p_household_id': householdId},
    );
    if (res == null) return HouseholdImmichConfig(serverUrl: null, apiKey: null);
    final map = res as Map<String, dynamic>;
    return HouseholdImmichConfig(
      serverUrl: map['server_url'] as String?,
      apiKey: map['api_key'] as String?,
    );
  }

  /// Saves server URL and API key for the household (key stored in Vault). Only call after user consent.
  Future<void> setHouseholdImmichConfig(
    String householdId, {
    required String serverUrl,
    required String apiKey,
  }) async {
    await _client.rpc(
      'set_household_immich_config',
      params: {
        'p_household_id': householdId,
        'p_server_url': serverUrl,
        'p_api_key': apiKey,
      },
    );
  }
}

class HouseholdImmichConfig {
  const HouseholdImmichConfig({this.serverUrl, this.apiKey});
  final String? serverUrl;
  final String? apiKey;
  bool get isConfigured =>
      serverUrl != null && serverUrl!.trim().isNotEmpty && apiKey != null && apiKey!.trim().isNotEmpty;
}
