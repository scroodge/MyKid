import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../journal_entry.dart';

const _boxName = 'journal_entries';

/// Simple local cache of journal entries (Hive). Sync with Supabase on load.
class JournalCache {
  static Future<void> init() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
  }

  static Box<String> get _box => Hive.box<String>(_boxName);

  static List<JournalEntry> getAll() {
    final list = <JournalEntry>[];
    for (final key in _box.keys) {
      final json = _box.get(key);
      if (json != null) {
        try {
          final map = jsonDecode(json) as Map<String, dynamic>;
          list.add(JournalEntry.fromJson(map));
        } catch (_) {}
      }
    }
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  static JournalEntry? get(String id) {
    final json = _box.get(id);
    if (json == null) return null;
    try {
      return JournalEntry.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> put(JournalEntry entry) async {
    await _box.put(entry.id, jsonEncode(entry.toJson()));
  }

  static Future<void> putAll(List<JournalEntry> entries) async {
    await _box.putAll(
      Map.fromEntries(entries.map((e) => MapEntry(e.id, jsonEncode(e.toJson())))),
    );
  }

  static Future<void> remove(String id) async {
    await _box.delete(id);
  }

  static Future<void> clear() async {
    await _box.clear();
  }
}
