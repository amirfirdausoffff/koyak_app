import 'package:flutter/foundation.dart';

import '../core/utils/backup_file_name.dart';

/// A backup stored in the user's Google Drive app-data folder.
@immutable
class BackupFile {
  const BackupFile({
    required this.id,
    required this.name,
    required this.backupDate,
    this.modifiedTime,
  });

  final String id;
  final String name;

  /// Date from the `koyak_DDMMYY.json` name.
  final DateTime backupDate;

  /// When Drive last wrote it (several backups on one day share a name).
  final DateTime? modifiedTime;

  /// Best timestamp to show the user.
  DateTime get takenAt => modifiedTime?.toLocal() ?? backupDate;

  /// Builds a [BackupFile] when [name] follows the Koyak naming scheme.
  static BackupFile? tryParse({
    required String? id,
    required String? name,
    DateTime? modifiedTime,
  }) {
    if (id == null || name == null) return null;
    final date = BackupFileName.parseDate(name);
    if (date == null) return null;
    return BackupFile(
      id: id,
      name: name,
      backupDate: date,
      modifiedTime: modifiedTime,
    );
  }

  /// Newest first: by the date in the name, then by Drive's modified time.
  static List<BackupFile> newestFirst(Iterable<BackupFile> files) =>
      [...files]..sort((a, b) {
        final byDate = b.backupDate.compareTo(a.backupDate);
        if (byDate != 0) return byDate;
        final aTime = a.modifiedTime ?? a.backupDate;
        final bTime = b.modifiedTime ?? b.backupDate;
        return bTime.compareTo(aTime);
      });

  /// Files beyond the newest [keep] — the ones to delete.
  static List<BackupFile> outdated(
    Iterable<BackupFile> files, {
    int keep = 5,
  }) => newestFirst(files).skip(keep).toList();
}
