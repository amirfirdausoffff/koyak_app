import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Everything a backup file carries: the user's records plus app settings.
@immutable
class BackupSnapshot {
  const BackupSnapshot({
    required this.createdAt,
    required this.data,
    required this.settings,
    this.version = currentVersion,
  });

  /// Throws [FormatException] for files that aren't Koyak backups.
  factory BackupSnapshot.fromMap(Map<String, dynamic> map) {
    if (map['app'] != appId) {
      throw const FormatException('Not a Koyak backup file');
    }
    final version = map['version'];
    if (version is! int || version > currentVersion) {
      throw FormatException('Unsupported backup version: $version');
    }
    final rawData = map['data'];
    if (rawData is! Map<String, dynamic>) {
      throw const FormatException('Backup has no data section');
    }

    return BackupSnapshot(
      version: version,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      data: {
        for (final entry in rawData.entries)
          if (entry.value is List)
            entry.key: (entry.value as List)
                .whereType<Map<String, dynamic>>()
                .toList(),
      },
      settings: Map<String, Object?>.from(
        map['settings'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  factory BackupSnapshot.fromJson(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Backup is not a JSON object');
    }
    return BackupSnapshot.fromMap(decoded);
  }

  static const appId = 'koyak';
  static const currentVersion = 1;

  final int version;
  final DateTime createdAt;

  /// Storage key → list of records (incomes, debts, expenses).
  final Map<String, List<Map<String, dynamic>>> data;

  final Map<String, Object?> settings;

  int get recordCount => data.values.fold(0, (sum, list) => sum + list.length);

  Map<String, dynamic> toMap() => {
    'app': appId,
    'version': version,
    'createdAt': createdAt.toIso8601String(),
    'data': data,
    'settings': settings,
  };

  String toJson() => jsonEncode(toMap());
}
