import 'package:flutter_test/flutter_test.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as gapis;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:koyak/core/constants/storage_keys.dart';
import 'package:koyak/core/errors/backup_exception.dart';
import 'package:koyak/models/backup_file.dart';
import 'package:koyak/models/backup_result.dart';
import 'package:koyak/models/backup_snapshot.dart';
import 'package:koyak/repositories/backup_repository.dart';
import 'package:koyak/services/backup_scheduler.dart';
import 'package:koyak/services/google_account_service.dart';
import 'package:koyak/services/google_drive_backup_service.dart';
import 'package:koyak/viewmodels/backup_view_model.dart';

import '../support/fake_backup_repository.dart';
import '../support/fake_preference_service.dart';

class _FakeAccounts implements GoogleAccountService {
  final requested = <({String email, bool interactive})>[];

  @override
  Future<String> pickAccount() async => 'amir@example.com';

  @override
  Future<gapis.AuthClient> clientFor(
    String email, {
    required bool interactive,
  }) async {
    requested.add((email: email, interactive: interactive));
    return gapis.authenticatedClient(
      MockClient((_) async => http.Response('{}', 200)),
      gapis.AccessCredentials(
        gapis.AccessToken(
          'Bearer',
          't',
          DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
        null,
        GoogleAccountService.scopes,
      ),
    );
  }

  @override
  Future<void> disconnect() async {}
}

class _FakeDrive implements GoogleDriveBackupService {
  BackupSnapshot? uploaded;
  BackupSnapshot? stored;

  @override
  Future<BackupFile> upload(
    http.Client client,
    BackupSnapshot snapshot, {
    required DateTime now,
  }) async {
    uploaded = snapshot;
    return BackupFile(id: '1', name: 'koyak_210926.json', backupDate: now);
  }

  @override
  Future<BackupFile?> findLatest(http.Client client) async => null;

  @override
  Future<BackupSnapshot> download(http.Client client, BackupFile file) async =>
      stored!;
}

class _FakeScheduler implements BackupScheduler {
  bool? enabled;

  @override
  Future<void> enable({bool reschedule = true}) async => enabled = true;

  @override
  Future<void> disable() async => enabled = false;
}

void main() {
  final now = DateTime(2026, 9, 21, 0, 0, 5);

  group('BackupRepository', () {
    late FakePreferenceService storage;
    late _FakeAccounts accounts;
    late _FakeDrive drive;
    late _FakeScheduler scheduler;
    late BackupRepository repository;

    setUp(() {
      storage = FakePreferenceService();
      accounts = _FakeAccounts();
      drive = _FakeDrive();
      scheduler = _FakeScheduler();
      repository = BackupRepository(
        storage: storage,
        accounts: accounts,
        drive: drive,
        scheduler: scheduler,
        clock: () => now,
      );
    });

    test('needs an account before touching Drive', () {
      expect(
        repository.backupNow(interactive: true),
        throwsA(
          isA<BackupException>().having(
            (e) => e.failure,
            'failure',
            BackupFailure.noAccount,
          ),
        ),
      );
    });

    test(
      'background backup uploads all data silently and stamps the time',
      () async {
        await repository.connectAccount();
        await storage.writeJsonList(StorageKeys.debts, [
          {'id': 'd1'},
        ]);

        await repository.backupNow(interactive: false);

        expect(accounts.requested.single.interactive, isFalse);
        expect(accounts.requested.single.email, 'amir@example.com');
        expect(drive.uploaded!.data[StorageKeys.debts], [
          {'id': 'd1'},
        ]);
        expect(drive.uploaded!.data.keys, containsAll(StorageKeys.data));
        expect(repository.lastBackupAt, now);
      },
    );

    test('restore replaces local data and re-applies auto-backup', () async {
      await repository.connectAccount();
      await storage.writeJsonList(StorageKeys.expenses, [
        {'id': 'old'},
      ]);
      drive.stored = BackupSnapshot(
        createdAt: now,
        data: {
          StorageKeys.incomes: [
            {'id': 'gaji'},
          ],
        },
        settings: const {'autoBackupEnabled': true},
      );

      await repository.restore(
        BackupFile(
          id: '1',
          name: 'koyak_200926.json',
          backupDate: DateTime(2026, 9, 20),
        ),
      );

      expect(storage.readJsonList(StorageKeys.incomes).single['id'], 'gaji');
      expect(storage.readJsonList(StorageKeys.expenses), isEmpty);
      expect(repository.autoBackupEnabled, isTrue);
      expect(scheduler.enabled, isTrue);
    });

    test('disconnect forgets the account and stops the schedule', () async {
      await repository.connectAccount();
      await repository.setAutoBackup(enabled: true);

      await repository.disconnect();

      expect(repository.accountEmail, isNull);
      expect(repository.autoBackupEnabled, isFalse);
      expect(scheduler.enabled, isFalse);
    });
  });

  group('BackupViewModel.connectAccount', () {
    late FakeBackupRepository repository;
    late int reloads;
    late BackupViewModel vm;
    final file = BackupFile(
      id: 'f',
      name: 'koyak_200926.json',
      backupDate: DateTime(2026, 9, 20),
    );

    setUp(() {
      repository = FakeBackupRepository();
      reloads = 0;
      vm = BackupViewModel(repository, onDataRestored: () async => reloads++);
    });

    test('no backup in Drive → fresh profile notice with the email', () async {
      final result = await vm.connectAccount();
      expect(result, isA<NoBackupFound>());
      expect((result as NoBackupFound).email, 'amir@example.com');
      expect(vm.isBusy, isFalse);
    });

    test('fresh phone restores the latest backup automatically', () async {
      repository.latest = file;

      final result = await vm.connectAccount();

      expect(result, isA<BackupRestored>());
      expect((result as BackupRestored).recordCount, 3);
      expect(repository.restoredFile, file);
      expect(reloads, 1);
    });

    test('phone with data is asked before anything is overwritten', () async {
      repository
        ..latest = file
        ..hasLocalData = true;

      final result = await vm.connectAccount();

      expect(result, isA<BackupAvailable>());
      expect(repository.restoredFile, isNull);
      expect(reloads, 0);
    });
  });
}
