import 'package:supabase_flutter/supabase_flutter.dart';

import 'journal_entry.dart';

/// Fetches and mutates journal entries via Supabase.
class JournalRepository {
  JournalRepository([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Returns journal entries visible to the current user (own + entries for shared household children).
  Future<List<JournalEntry>> getEntries({
    int limit = 50,
    int offset = 0,
    DateTime? from,
    DateTime? to,
    String? childId,
  }) async {
    if (_userId == null) return [];
    var query = _client.from('journal_entries').select();
    if (childId != null) {
      query = query.eq('child_id', childId);
    }
    if (from != null) {
      query = query.gte('date', from.toIso8601String().split('T').first);
    }
    if (to != null) {
      query = query.lte('date', to.toIso8601String().split('T').first);
    }
    final res = await query
        .order('date', ascending: false)
        .range(offset, offset + limit - 1);
    return (res as List).map((e) => JournalEntry.fromJson(e)).toList();
  }

  Future<JournalEntry?> getEntry(String id) async {
    if (_userId == null) return null;
    final res = await _client
        .from('journal_entries')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (res == null) return null;
    return JournalEntry.fromJson(res);
  }

  Future<JournalEntry?> createEntry({
    required DateTime date,
    required String text,
    required List<JournalEntryAsset> assets,
    String? childId,
    String? location,
  }) async {
    final uid = _userId;
    if (uid == null) return null;
    final payload = {
      'user_id': uid,
      'date': date.toIso8601String().split('T').first,
      'text': text,
      'assets': assets.map((a) => a.toJson()).toList(),
      if (childId != null) 'child_id': childId,
      if (location != null && location.isNotEmpty) 'location': location,
    };
    final res = await _client.from('journal_entries').insert(payload).select().single();
    return JournalEntry.fromJson(res);
  }

  Future<JournalEntry?> updateEntry(
    String id, {
    required DateTime date,
    required String text,
    required List<JournalEntryAsset> assets,
    String? childId,
    String? location,
  }) async {
    final uid = _userId;
    if (uid == null) return null;
    final payload = {
      'date': date.toIso8601String().split('T').first,
      'text': text,
      'assets': assets.map((a) => a.toJson()).toList(),
      'child_id': childId,
      if (location != null) 'location': location,
    };
    final res = await _client
        .from('journal_entries')
        .update(payload)
        .eq('id', id)
        .select()
        .maybeSingle();
    if (res == null) return null;
    return JournalEntry.fromJson(res);
  }

  Future<bool> deleteEntry(String id) async {
    if (_userId == null) return false;
    await _client.from('journal_entries').delete().eq('id', id);
    return true;
  }
}
