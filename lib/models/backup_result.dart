import '../core/errors/backup_exception.dart';
import 'backup_file.dart';

/// What happened after a backup / restore action, for the UI to present.
sealed class BackupResult {
  const BackupResult();
}

class BackupUploaded extends BackupResult {
  const BackupUploaded(this.file);

  final BackupFile file;
}

/// The account has no Koyak backup yet — a fresh profile is used.
class NoBackupFound extends BackupResult {
  const NoBackupFound(this.email);

  final String email;
}

/// A backup exists, but the phone already has data: ask before replacing.
class BackupAvailable extends BackupResult {
  const BackupAvailable(this.file);

  final BackupFile file;
}

class BackupRestored extends BackupResult {
  const BackupRestored(this.file, {required this.recordCount});

  final BackupFile file;
  final int recordCount;
}

class BackupFailed extends BackupResult {
  const BackupFailed(this.failure);

  final BackupFailure failure;
}
