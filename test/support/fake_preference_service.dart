import 'dart:convert';

import 'package:koyak/services/preference_service.dart';

/// In-memory [PreferenceService]; values are stored as the real one would.
class FakePreferenceService implements PreferenceService {
  final Map<String, Object> values = {};

  @override
  List<Map<String, dynamic>> readJsonList(String key) {
    final raw = values[key] as String?;
    if (raw == null) return const [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  @override
  Future<void> writeJsonList(
    String key,
    List<Map<String, dynamic>> items,
  ) async => values[key] = jsonEncode(items);

  @override
  String? readString(String key) => values[key] as String?;

  @override
  Future<void> writeString(String key, String value) async =>
      values[key] = value;

  @override
  bool? readBool(String key) => values[key] as bool?;

  @override
  Future<void> writeBool(String key, {required bool value}) async =>
      values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);

  @override
  Future<void> reload() async {}
}
