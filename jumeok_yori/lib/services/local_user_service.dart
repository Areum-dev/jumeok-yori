import 'package:shared_preferences/shared_preferences.dart';

class LocalUserService {
  static const _keyRecentReg = 'recent_registered_ids';
  static const _keyRecentStarter = 'recent_starter_ids';
  static const _keySavedReg = 'saved_registered_ids';
  static const _keySavedStarter = 'saved_starter_ids';

  // ── 최근 추천 (등록 메뉴) ──
  static Future<List<String>> getRecentRegisteredIds() =>
      _getList(_keyRecentReg);
  static Future<void> addRecentRegisteredId(String id) =>
      _addToFront(_keyRecentReg, id, max: 20);

  // ── 최근 추천 (스타터 메뉴) ──
  static Future<List<String>> getRecentStarterIds() =>
      _getList(_keyRecentStarter);
  static Future<void> addRecentStarterId(String id) =>
      _addToFront(_keyRecentStarter, id, max: 20);

  static Future<void> clearRecent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRecentReg);
    await prefs.remove(_keyRecentStarter);
  }

  // ── 저장한 메뉴 ──
  static Future<List<String>> getSavedRegisteredIds() => _getList(_keySavedReg);
  static Future<List<String>> getSavedStarterIds() =>
      _getList(_keySavedStarter);

  static Future<void> toggleSaved({
    required bool isRegistered,
    required String id,
  }) async {
    final key = isRegistered ? _keySavedReg : _keySavedStarter;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(key) ?? [];
    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.insert(0, id);
    }
    await prefs.setStringList(key, list);
  }

  static Future<bool> isSaved({
    required bool isRegistered,
    required String id,
  }) async {
    final key = isRegistered ? _keySavedReg : _keySavedStarter;
    final list = await _getList(key);
    return list.contains(id);
  }

  // ── helpers ──
  static Future<List<String>> _getList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? [];
  }

  static Future<void> _addToFront(
    String key,
    String id, {
    required int max,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(key) ?? [];
    list.remove(id);
    list.insert(0, id);
    await prefs.setStringList(key, list.take(max).toList());
  }
}
