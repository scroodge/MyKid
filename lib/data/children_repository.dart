import 'package:supabase_flutter/supabase_flutter.dart';

import 'child.dart';

/// CRUD for children profiles (Supabase).
class ChildrenRepository {
  ChildrenRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Future<List<Child>> getAll() async {
    final uid = _userId;
    if (uid == null) return [];
    final res = await _client
        .from('children')
        .select()
        .eq('user_id', uid)
        .order('name');
    return (res as List).map((e) => Child.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Child?> get(String id) async {
    final uid = _userId;
    if (uid == null) return null;
    final res = await _client
        .from('children')
        .select()
        .eq('id', id)
        .eq('user_id', uid)
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
    final payload = {
      'user_id': uid,
      'name': name,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
    };
    final res = await _client.from('children').insert(payload).select().single();
    return Child.fromJson(res as Map<String, dynamic>);
  }

  Future<Child?> update(
    String id, {
    String? name,
    DateTime? dateOfBirth,
    String? immichAlbumId,
    String? avatarUrl,
  }) async {
    final uid = _userId;
    if (uid == null) return null;
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (dateOfBirth != null) payload['date_of_birth'] = dateOfBirth.toIso8601String().split('T').first;
    if (immichAlbumId != null) payload['immich_album_id'] = immichAlbumId;
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
