import 'package:workmanager/workmanager.dart';

/// Schedules the daily Drive backup around 12:00 AM.
///
/// The OS decides the exact moment: Android may defer it (Doze, battery
/// saver) and iOS runs background refresh when it sees fit. It needs a
/// network connection and retries later if the phone is offline.
class BackupScheduler {
  const BackupScheduler();

  /// Also the iOS BGTaskScheduler identifier (see Info.plist).
  static const taskId = 'com.koyak.dailyBackup';

  /// Must run on every app start with the top-level [callbackDispatcher].
  static Future<void> initialize(Function callbackDispatcher) =>
      Workmanager().initialize(callbackDispatcher);

  Future<void> enable({bool reschedule = true}) =>
      Workmanager().registerPeriodicTask(
        taskId,
        taskId,
        frequency: const Duration(hours: 24),
        initialDelay: delayUntilMidnight(DateTime.now()),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: reschedule
            ? ExistingPeriodicWorkPolicy.update
            : ExistingPeriodicWorkPolicy.keep,
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 15),
      );

  Future<void> disable() => Workmanager().cancelByUniqueName(taskId);

  /// Time left until the next 12:00 AM.
  static Duration delayUntilMidnight(DateTime now) =>
      DateTime(now.year, now.month, now.day + 1).difference(now);
}
