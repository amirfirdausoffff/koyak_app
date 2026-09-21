import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'app_dependencies.dart';
import 'background/backup_worker.dart';
import 'core/constants/app_strings.dart';
import 'services/backup_scheduler.dart';
import 'services/preference_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(AppStrings.dateLocale);
  await BackupScheduler.initialize(backupCallbackDispatcher);
  final storage = await PreferenceService.create();
  final dependencies = AppDependencies.local(storage);
  // Re-arm the daily backup if it was on; never block startup on it.
  dependencies.backupRepository.ensureScheduled().ignore();

  runApp(KoyakApp(dependencies: dependencies));
}
