import 'package:supabase_flutter/supabase_flutter.dart';

import 'child.dart';

/// CRUD for children profiles (Supabase).
class ChildrenRepository {
  ChildrenRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Returns all children visible to the current user: own + children in their household(s).
  Future<List<Child>> getAll() async {
    if (_userId == null) return [];
    final res = await _client
        .from('children')
        .select()
        .order('name');
    return (res as List).map((e) => Child.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Child?> get(String id) async {
    if (_userId == null) return null;
    final res = await _client
        .from('children')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (res == null) return null;
    return Child.fromJson(res as Map<String, dynamic>);
  }

  Future<Child?> create({
    required String name,
    DateTime? dateOfBirth,
  }) async {
    final uid = _userId;
    if (uid == null) return null;
    // Get household_id if user is in a household, otherwise explicitly set to null
    final householdId = await _getMyFirstHouseholdId();
    final payload = <String, dynamic>{
      'user_id': uid,
      'name': name,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
      // Explicitly set household_id: null if user not in household, or actual id if in household
      'household_id': householdId,
    };
    try {
      final res = await _client.from('children').insert(payload).select().single();
      return Child.fromJson(res as Map<String, dynamic>);
    } catch (e) {
      // Log error for debugging
      print('Error creating child: $e');
      print('Payload: $payload');
      print('User ID: $uid');
      print('Household ID: $householdId');
      rethrow;
    }
  }

  Future<String?> _getMyFirstHouseholdId() async {
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

  Future<Child?> update(
    String id, {
    String? name,
    DateTime? dateOfBirth,
    String? immichAlbumId,
    String? immichPersonId,
    bool clearImmichPersonId = false,
    String? avatarUrl,
  }) async {
    final uid = _userId;
    if (uid == null) return null;
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (dateOfBirth != null) payload['date_of_birth'] = dateOfBirth.toIso8601String().split('T').first;
    if (immichAlbumId != null) payload['immich_album_id'] = immichAlbumId;
    if (clearImmichPersonId) {
      payload['immich_person_id'] = null;
    } else if (immichPersonId != null) {
      payload['immich_person_id'] = immichPersonId;
    }
    if (avatarUrl != null) payload['avatar_url'] = avatarUrl;
    if (payload.isEmpty) return get(id);
    final res = await _client
        .from('children')
        .update(payload)
        .eq('id', id)
        .eq('user_id', uid)
        .select()
        .maybeSingle();
    if (res == null) return null;
    return Child.fromJson(res as Map<String, dynamic>);
  }

  Future<bool> delete(String id) async {
    final uid = _userId;
    if (uid == null) return false;
    await _client.from('children').delete().eq('id', id).eq('user_id', uid);
    return true;
  }
}
