import 'package:http/http.dart' as http;

import '../core/constants/storage_keys.dart';
import '../core/errors/backup_exception.dart';
import '../models/backup_file.dart';
import '../models/backup_snapshot.dart';
import '../services/backup_scheduler.dart';
import '../services/google_account_service.dart';
import '../services/google_drive_backup_service.dart';
import '../services/preference_service.dart';

/// Single entry point for backup & restore, shared by the settings screen
/// and the background worker. Owns the backup settings kept on the device.
class BackupRepository {
  BackupRepository({
    required this._storage,
    GoogleAccountService? accounts,
    this._drive = const GoogleDriveBackupService(),
    this._scheduler = const BackupScheduler(),
    DateTime Function()? clock,
  }) : _accounts = accounts ?? GoogleAccountService(),
       _clock = clock ?? DateTime.now;

  static const _autoBackupSetting = 'autoBackupEnabled';

  final PreferenceService _storage;
  final GoogleAccountService _accounts;
  final GoogleDriveBackupService _drive;
  final BackupScheduler _scheduler;
  final DateTime Function() _clock;

  String? get accountEmail =>
      _storage.readString(StorageKeys.backupAccountEmail);

  bool get autoBackupEnabled =>
      _storage.readBool(StorageKeys.autoBackupEnabled) ?? false;

  DateTime? get lastBackupAt =>
      DateTime.tryParse(_storage.readString(StorageKeys.lastBackupAt) ?? '');

  /// True when the phone already holds any income, debt or expense.
  bool get hasLocalData =>
      StorageKeys.data.any((key) => _storage.readJsonList(key).isNotEmpty);

  /// Picks up settings written by the background worker's isolate.
  Future<void> reload() => _storage.reload();

  /// Device account picker + Drive consent. Remembers the chosen email.
  Future<String> connectAccount() async {
    final email = await _accounts.pickAccount();
    await _storage.writeString(StorageKeys.backupAccountEmail, email);
    return email;
  }

  /// Forgets the account and stops auto-backup. Files in Drive are kept.
  Future<void> disconnect() async {
    await _accounts.disconnect();
    await _scheduler.disable();
    await _storage.writeBool(StorageKeys.autoBackupEnabled, value: false);
    await _storage.remove(StorageKeys.backupAccountEmail);
  }

  Future<void> setAutoBackup({required bool enabled}) async {
    if (enabled && accountEmail == null) {
      throw const BackupException(BackupFailure.noAccount);
    }
    await _storage.writeBool(StorageKeys.autoBackupEnabled, value: enabled);
    await (enabled ? _scheduler.enable() : _scheduler.disable());
  }

  /// Re-registers the daily task after app start (keeps an existing one).
  Future<void> ensureScheduled() async {
    if (autoBackupEnabled && accountEmail != null) {
      await _scheduler.enable(reschedule: false);
    }
  }

  /// Uploads the current data. [interactive] false never shows UI, for
  /// background runs.
  Future<BackupFile> backupNow({required bool interactive}) =>
      _withDrive(interactive: interactive, (client) async {
        final now = _clock();
        final file = await _drive.upload(client, _capture(now), now: now);
        await _storage.writeString(
          StorageKeys.lastBackupAt,
          now.toIso8601String(),
        );
        return file;
      });

  /// Newest `koyak_DDMMYY.json` in the account, or null when none exists.
  Future<BackupFile?> findLatestBackup() =>
      _withDrive(interactive: true, _drive.findLatest);

  /// Downloads [file] and replaces the local data with it.
  Future<BackupSnapshot> restore(BackupFile file) =>
      _withDrive(interactive: true, (client) async {
        final snapshot = await _drive.download(client, file);
        await _apply(snapshot);
        await _rememberBackupTime(file.takenAt);
        return snapshot;
      });

  BackupSnapshot _capture(DateTime now) => BackupSnapshot(
    createdAt: now,
    data: {for (final key in StorageKeys.data) key: _storage.readJsonList(key)},
    settings: {_autoBackupSetting: autoBackupEnabled},
  );

  Future<void> _apply(BackupSnapshot snapshot) async {
    for (final key in StorageKeys.data) {
      await _storage.writeJsonList(key, snapshot.data[key] ?? const []);
    }
    final autoBackup = snapshot.settings[_autoBackupSetting];
    if (autoBackup is bool) await setAutoBackup(enabled: autoBackup);
  }

  Future<void> _rememberBackupTime(DateTime time) async {
    final current = lastBackupAt;
    if (current == null || time.isAfter(current)) {
      await _storage.writeString(
        StorageKeys.lastBackupAt,
        time.toIso8601String(),
      );
    }
  }

  Future<T> _withDrive<T>(
    Future<T> Function(http.Client client) action, {
    required bool interactive,
  }) async {
    final email = accountEmail;
    if (email == null) throw const BackupException(BackupFailure.noAccount);

    final client = await _accounts.clientFor(email, interactive: interactive);
    try {
      return await action(client);
    } finally {
      client.close();
    }
  }
}
