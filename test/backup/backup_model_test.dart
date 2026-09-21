import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:googleapis/drive/v3.dart' show DetailedApiRequestError;
import 'package:koyak/core/errors/backup_exception.dart';
import 'package:koyak/core/utils/backup_file_name.dart';
import 'package:koyak/models/backup_file.dart';
import 'package:koyak/models/backup_snapshot.dart';
import 'package:koyak/services/backup_scheduler.dart';

void main() {
  group('BackupFileName', () {
    test('formats koyak_DDMMYY.json', () {
      expect(
        BackupFileName.forDate(DateTime(2026, 9, 21)),
        'koyak_210926.json',
      );
      expect(BackupFileName.forDate(DateTime(2027, 1, 5)), 'koyak_050127.json');
    });

    test('parses dates back and rejects other names', () {
      expect(
        BackupFileName.parseDate('koyak_210926.json'),
        DateTime(2026, 9, 21),
      );
      expect(BackupFileName.parseDate('koyak_310226.json'), isNull);
      expect(BackupFileName.parseDate('koyak_21092026.json'), isNull);
      expect(BackupFileName.parseDate('notes.json'), isNull);
    });
  });

  group('BackupFile selection', () {
    BackupFile file(String name, {DateTime? modified}) =>
        BackupFile.tryParse(id: name, name: name, modifiedTime: modified)!;

    test('latest is picked by the date in the name, not list order', () {
      final files = [
        file('koyak_010926.json'),
        file('koyak_150926.json'),
        file('koyak_311226.json'),
        file('koyak_020127.json'),
      ];
      expect(BackupFile.newestFirst(files).first.name, 'koyak_020127.json');
    });

    test('keeps the newest 5 and marks the rest for deletion', () {
      final files = [
        for (var day = 1; day <= 7; day++)
          file('koyak_${day.toString().padLeft(2, '0')}0926.json'),
      ];
      final outdated = BackupFile.outdated(files, keep: 5);
      expect(outdated.map((f) => f.name), [
        'koyak_020926.json',
        'koyak_010926.json',
      ]);
    });

    test('same-day files fall back to Drive modified time', () {
      final older = file(
        'koyak_210926.json',
        modified: DateTime.utc(2026, 9, 21, 1),
      );
      final newer = BackupFile(
        id: 'b',
        name: 'koyak_210926.json',
        backupDate: DateTime(2026, 9, 21),
        modifiedTime: DateTime.utc(2026, 9, 21, 9),
      );
      expect(BackupFile.newestFirst([older, newer]).first.id, 'b');
    });
  });

  group('BackupSnapshot', () {
    test('round-trips through JSON', () {
      final snapshot = BackupSnapshot(
        createdAt: DateTime(2026, 9, 21),
        data: {
          'koyak.debts': [
            {'id': 'd1', 'title': 'PTPTN'},
          ],
        },
        settings: const {'autoBackupEnabled': true},
      );
      final back = BackupSnapshot.fromJson(snapshot.toJson());
      expect(back.data['koyak.debts']!.single['title'], 'PTPTN');
      expect(back.settings['autoBackupEnabled'], isTrue);
      expect(back.recordCount, 1);
    });

    test('rejects foreign or future files', () {
      expect(
        () => BackupSnapshot.fromJson('{"app":"other","version":1,"data":{}}'),
        throwsFormatException,
      );
      expect(
        () => BackupSnapshot.fromJson('{"app":"koyak","version":99,"data":{}}'),
        throwsFormatException,
      );
      expect(() => BackupSnapshot.fromJson('[]'), throwsFormatException);
    });
  });

  test('errors are classified for the user', () {
    BackupFailure failureOf(Object e) => BackupException.from(e).failure;

    expect(failureOf(const SocketException('down')), BackupFailure.offline);
    expect(
      failureOf(DetailedApiRequestError(401, 'expired')),
      BackupFailure.notAuthorized,
    );
    expect(
      failureOf(
        const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
      ),
      BackupFailure.cancelled,
    );
    expect(
      failureOf(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
        ),
      ),
      BackupFailure.notConfigured,
    );
    expect(
      BackupException.from(const SocketException('x')).isTransient,
      isTrue,
    );
  });

  test('first run is scheduled for the coming midnight', () {
    expect(
      BackupScheduler.delayUntilMidnight(DateTime(2026, 9, 21, 23, 30)),
      const Duration(minutes: 30),
    );
    expect(
      BackupScheduler.delayUntilMidnight(DateTime(2026, 9, 30, 12)),
      const Duration(hours: 12),
    );
  });
}
