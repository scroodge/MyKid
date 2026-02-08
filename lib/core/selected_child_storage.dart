import 'package:shared_preferences/shared_preferences.dart';

const _keySelectedChildId = 'selected_child_id';

/// Persists the selected child id so it can be restored on next launch.
class SelectedChildStorage {
  SelectedChildStorage([SharedPreferences? prefs]) : _prefs = prefs;

  SharedPreferences? _prefs;
  SharedPreferences get prefs => _prefs!;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<String?> getSelectedChildId() async {
    await init();
    return prefs.getString(_keySelectedChildId);
  }

  Future<void> setSelectedChildId(String? id) async {
    await init();
    if (id == null) {
      await prefs.remove(_keySelectedChildId);
    } else {
      await prefs.setString(_keySelectedChildId, id);
    }
  }
}
