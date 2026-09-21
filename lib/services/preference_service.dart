import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/storage_keys.dart';

/// Stores JSON in the phone's local cache only — nothing leaves the device
/// unless the user turns on Google Drive backup.
class PreferenceService {
  PreferenceService(this._prefs);

  static Future<PreferenceService> create() async {
    final prefs = await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: StorageKeys.all,
      ),
    );
    return PreferenceService(prefs);
  }

  final SharedPreferencesWithCache _prefs;

  /// Returns an empty list when the key is missing or the JSON is corrupt.
  List<Map<String, dynamic>> readJsonList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      return decoded is List
          ? decoded.whereType<Map<String, dynamic>>().toList()
          : const [];
    } on FormatException {
      return const [];
    }
  }

  Future<void> writeJsonList(String key, List<Map<String, dynamic>> items) =>
      _prefs.setString(key, jsonEncode(items));

  String? readString(String key) => _prefs.getString(key);

  Future<void> writeString(String key, String value) =>
      _prefs.setString(key, value);

  bool? readBool(String key) => _prefs.getBool(key);

  Future<void> writeBool(String key, {required bool value}) =>
      _prefs.setBool(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  /// Picks up writes made by another isolate (e.g. the background backup).
  Future<void> reload() => _prefs.reloadCache();
}
