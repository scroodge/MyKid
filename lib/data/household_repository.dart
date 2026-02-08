import 'package:supabase_flutter/supabase_flutter.dart';

/// Household (family) membership and settings. Used for shared Immich config.
class HouseholdRepository {
  HouseholdRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Returns the first household id the current user is a member of, or null.
  Future<String?> getMyFirstHouseholdId() async {
    final uid = _userId;
    if (uid == null) return null;
    final res = await _client
        .from('household_members')
        .select('household_id')
        .eq('user_id', uid)
        .limit(1)
        .maybeSingle();
    final map = res as Map<String, dynamic>?;
    return map?['household_id'] as String?;
  }

  /// Returns all household ids the current user is a member of.
  Future<List<String>> getMyHouseholdIds() async {
    final uid = _userId;
    if (uid == null) return [];
    final res = await _client
        .from('household_members')
        .select('household_id')
        .eq('user_id', uid);
    return (res as List)
        .map((e) => (e as Map<String, dynamic>)['household_id'] as String)
        .toList();
  }

  /// Creates a new household with current user as owner and single member. Returns household id or null.
  Future<String?> createHousehold({String? name}) async {
    final uid = _userId;
    if (uid == null) return null;
    final insertRes = await _client
        .from('households')
        .insert({'owner_id': uid, if (name != null && name.isNotEmpty) 'name': name})
        .select('id')
        .single();
    final householdId = insertRes['id'] as String?;
    if (householdId == null) return null;
    await _client.from('household_members').insert({
      'household_id': householdId,
      'user_id': uid,
      'role': 'owner',
    });
    return householdId;
  }

  /// Ensures current user has at least one household; creates one if not. Returns its id or null.
  Future<String?> getOrCreateMyHousehold() async {
    final existing = await getMyFirstHouseholdId();
    if (existing != null) return existing;
    return createHousehold();
  }

  /// Returns whether the given household has Immich configured (has server url and secret).
  Future<bool> householdHasImmichConfig(String householdId) async {
    final res = await _client
        .from('household_settings')
        .select('household_id')
        .eq('household_id', householdId)
        .not('immich_server_url', 'is', null)
        .not('immich_vault_secret_id', 'is', null)
        .maybeSingle();
    return res != null;
  }
}
