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
  /// Uses RPC function to bypass RLS issues.
  /// Throws exception on error.
  Future<String?> createHousehold({String? name}) async {
    final uid = _userId;
    if (uid == null) throw Exception('User not authenticated');
    
    try {
      // Use RPC function that bypasses RLS
      final res = await _client.rpc(
        'create_household',
        params: {'p_name': name?.isEmpty == true ? null : name},
      );
      return res as String?;
    } catch (e) {
      // Fallback to direct insert if RPC doesn't exist
      try {
        final insertRes = await _client
            .from('households')
            .insert({'owner_id': uid, if (name != null && name.isNotEmpty) 'name': name})
            .select('id')
            .single();
        final householdId = insertRes['id'] as String?;
        if (householdId == null) throw Exception('Failed to create household: no ID returned');
        
        await _client.from('household_members').insert({
          'household_id': householdId,
          'user_id': uid,
          'role': 'owner',
        });
        
        return householdId;
      } catch (fallbackError) {
        throw Exception('Failed to create household: $e (fallback also failed: $fallbackError)');
      }
    }
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

  /// Gets household name by id. Returns null if not found or no name set.
  Future<String?> getHouseholdName(String householdId) async {
    final res = await _client
        .from('households')
        .select('name')
        .eq('id', householdId)
        .maybeSingle();
    final map = res as Map<String, dynamic>?;
    final name = map?['name'] as String?;
    return (name != null && name.trim().isNotEmpty) ? name.trim() : null;
  }

  /// Returns true if the current user is the owner of the given household.
  Future<bool> isHouseholdOwner(String householdId) async {
    final uid = _userId;
    if (uid == null) return false;
    final res = await _client
        .from('household_members')
        .select('role')
        .eq('household_id', householdId)
        .eq('user_id', uid)
        .maybeSingle();
    final map = res as Map<String, dynamic>?;
    return map?['role'] == 'owner';
  }

  /// Returns list of members in the household: [{ userId, role }].
  /// Only call when current user is a member (RLS allows read).
  Future<List<({String userId, String role})>> getHouseholdMembers(String householdId) async {
    final res = await _client
        .from('household_members')
        .select('user_id, role')
        .eq('household_id', householdId)
        .order('joined_at');
    return (res as List).map((e) {
      final m = e as Map<String, dynamic>;
      return (
        userId: m['user_id'] as String,
        role: m['role'] as String? ?? 'member',
      );
    }).toList();
  }
}
