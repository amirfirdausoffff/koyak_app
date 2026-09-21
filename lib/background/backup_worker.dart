import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../core/errors/backup_exception.dart';
import '../repositories/backup_repository.dart';
import '../services/backup_scheduler.dart';
import '../services/preference_service.dart';

/// Entry point the OS calls for the daily backup, in its own isolate.
@pragma('vm:entry-point')
void backupCallbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    if (task != BackupScheduler.taskId) return true;
    DartPluginRegistrant.ensureInitialized();

    final repository = BackupRepository(
      storage: await PreferenceService.create(),
    );
    if (!repository.autoBackupEnabled || repository.accountEmail == null) {
      return true;
    }

    try {
      await repository.backupNow(interactive: false);
      return true;
    } on BackupException catch (error) {
      debugPrint('Koyak auto-backup failed: $error');
      // false asks the OS to retry later; pointless when the user must act.
      return !error.isTransient;
    }
  });
}
