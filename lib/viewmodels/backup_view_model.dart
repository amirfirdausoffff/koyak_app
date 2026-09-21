import 'package:flutter/foundation.dart';

import '../core/errors/backup_exception.dart';
import '../models/backup_file.dart';
import '../models/backup_result.dart';
import '../repositories/backup_repository.dart';

enum BackupTask { connecting, backingUp, checking, restoring }

/// State for the Google Drive backup settings. Actions return a
/// [BackupResult] and never throw, so the view only decides how to present.
class BackupViewModel extends ChangeNotifier {
  BackupViewModel(this._repository, {required this.onDataRestored});

  final BackupRepository _repository;

  /// Reloads the data view models after a restore replaced local storage.
  final Future<void> Function() onDataRestored;

  BackupTask? _task;
  bool _isDisposed = false;

  String? get accountEmail => _repository.accountEmail;
  bool get hasAccount => accountEmail != null;
  bool get autoBackupEnabled => _repository.autoBackupEnabled;
  DateTime? get lastBackupAt => _repository.lastBackupAt;

  BackupTask? get task => _task;
  bool get isBusy => _task != null;

  /// Pick an account, then look for its latest backup. A fresh phone gets
  /// it restored straight away; a phone with data is asked first.
  Future<BackupResult> connectAccount() =>
      _run(BackupTask.connecting, () async {
        final email = await _repository.connectAccount();
        _notify();
        return _findAndMaybeRestore(email, restoreIfEmpty: true);
      });

  /// 'Semak & Load Backup': finds the newest file; never overwrites
  /// silently.
  Future<BackupResult> checkForBackup() => _run(
    BackupTask.checking,
    () => _findAndMaybeRestore(accountEmail ?? '', restoreIfEmpty: false),
  );

  Future<BackupResult> backupNow() => _run(BackupTask.backingUp, () async {
    final file = await _repository.backupNow(interactive: true);
    return BackupUploaded(file);
  });

  Future<BackupResult> restore(BackupFile file) =>
      _run(BackupTask.restoring, () => _restore(file));

  Future<BackupResult?> setAutoBackup({required bool enabled}) async {
    try {
      await _repository.setAutoBackup(enabled: enabled);
      return null;
    } catch (error) {
      return BackupFailed(BackupException.from(error).failure);
    } finally {
      _notify();
    }
  }

  Future<void> disconnect() async {
    await _repository.disconnect();
    _notify();
  }

  /// Re-reads settings, e.g. after the background backup ran.
  Future<void> refresh() async {
    await _repository.reload();
    _notify();
  }

  Future<BackupResult> _findAndMaybeRestore(
    String email, {
    required bool restoreIfEmpty,
  }) async {
    final latest = await _repository.findLatestBackup();
    if (latest == null) return NoBackupFound(email);
    if (restoreIfEmpty && !_repository.hasLocalData) {
      _task = BackupTask.restoring;
      _notify();
      return _restore(latest);
    }
    return BackupAvailable(latest);
  }

  Future<BackupResult> _restore(BackupFile file) async {
    final snapshot = await _repository.restore(file);
    await onDataRestored();
    return BackupRestored(file, recordCount: snapshot.recordCount);
  }

  Future<BackupResult> _run(
    BackupTask task,
    Future<BackupResult> Function() action,
  ) async {
    if (isBusy) return const BackupFailed(BackupFailure.cancelled);
    _task = task;
    _notify();
    try {
      return await action();
    } catch (error) {
      return BackupFailed(BackupException.from(error).failure);
    } finally {
      _task = null;
      _notify();
    }
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
