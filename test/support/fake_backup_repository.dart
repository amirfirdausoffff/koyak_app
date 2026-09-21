import 'package:koyak/models/backup_file.dart';
import 'package:koyak/models/backup_snapshot.dart';
import 'package:koyak/repositories/backup_repository.dart';

/// Offline stand-in so widget and view-model tests never touch Google.
class FakeBackupRepository implements BackupRepository {
  @override
  String? accountEmail;

  @override
  bool autoBackupEnabled = false;

  @override
  DateTime? lastBackupAt;

  @override
  bool hasLocalData = false;

  /// What [findLatestBackup] returns.
  BackupFile? latest;
  BackupFile? restoredFile;

  @override
  Future<void> reload() async {}

  @override
  Future<String> connectAccount() async => accountEmail = 'amir@example.com';

  @override
  Future<void> disconnect() async => accountEmail = null;

  @override
  Future<void> setAutoBackup({required bool enabled}) async =>
      autoBackupEnabled = enabled;

  @override
  Future<void> ensureScheduled() async {}

  @override
  Future<BackupFile> backupNow({required bool interactive}) async => BackupFile(
    id: 'new',
    name: 'koyak_210926.json',
    backupDate: DateTime(2026, 9, 21),
  );

  @override
  Future<BackupFile?> findLatestBackup() async => latest;

  @override
  Future<BackupSnapshot> restore(BackupFile file) async {
    restoredFile = file;
    return BackupSnapshot(
      createdAt: file.backupDate,
      data: {
        'koyak.incomes': [
          {'id': 'g'},
        ],
        'koyak.expenses': [
          {'id': 'e1'},
          {'id': 'e2'},
        ],
      },
      settings: const {},
    );
  }
}
