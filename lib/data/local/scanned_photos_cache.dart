import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

const _boxName = 'scanned_photos';
const _scannedIdsKey = 'scanned_ids';
const _lastScanKey = 'last_scan';

/// Cache of already-scanned photo IDs to avoid rescanning. Stored in Hive.
class ScannedPhotosCache {
  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
  }

  static Box<String> get _box => Hive.box<String>(_boxName);

  static Set<String> getScannedIds() {
    final json = _box.get(_scannedIdsKey);
    if (json == null) return {};
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> addScannedIds(Iterable<String> ids) async {
    final existing = getScannedIds();
    existing.addAll(ids);
    await _box.put(
      _scannedIdsKey,
      jsonEncode(existing.toList()),
    );
  }

  static bool isScanned(String id) => getScannedIds().contains(id);

  static DateTime? get lastScan {
    final s = _box.get(_lastScanKey);
    if (s == null) return null;
    return DateTime.tryParse(s);
  }

  static Future<void> setLastScan(DateTime when) async {
    await _box.put(_lastScanKey, when.toIso8601String());
  }

  static Future<void> clear() async {
    await _box.clear();
  }
}
