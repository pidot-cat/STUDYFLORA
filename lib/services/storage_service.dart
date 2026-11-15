import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Thin JSON layer over SharedPreferences (SRS §5 local storage, FR-6.1).
/// User data is namespaced by user id so two accounts on one phone never mix.
class StorageService {
  StorageService._(this._p);
  final SharedPreferences _p;

  static Future<StorageService> create() async => StorageService._(await SharedPreferences.getInstance());

  Map<String, dynamic>? readJson(String key) {
    final s = _p.getString(key);
    if (s == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(s) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeJson(String key, Map<String, dynamic> value) => _p.setString(key, jsonEncode(value));

  bool getBool(String key, [bool fallback = false]) => _p.getBool(key) ?? fallback;
  Future<void> setBool(String key, bool v) => _p.setBool(key, v);
  String? getString(String key) => _p.getString(key);
  Future<void> setString(String key, String v) => _p.setString(key, v);
  int getInt(String key, [int fallback = 0]) => _p.getInt(key) ?? fallback;
  Future<void> setInt(String key, int v) => _p.setInt(key, v);
  Future<void> remove(String key) => _p.remove(key);

  static String gameKey(String uid) => 'sf.game.$uid';
  static String studyKey(String uid) => 'sf.study.$uid';
  static String syncKey(String uid) => 'sf.sync.$uid';
}
