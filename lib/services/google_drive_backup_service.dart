import 'dart:async';
import 'dart:convert';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../core/errors/backup_exception.dart';
import '../core/utils/backup_file_name.dart';
import '../models/backup_file.dart';
import '../models/backup_snapshot.dart';

/// Reads and writes Koyak backups in the hidden Drive `appDataFolder`.
/// Stateless: every call receives an authorised [http.Client].
class GoogleDriveBackupService {
  const GoogleDriveBackupService();

  static const maxBackups = 5;
  static const _space = 'appDataFolder';
  static const _timeout = Duration(seconds: 30);

  /// Uploads [snapshot] as `koyak_DDMMYY.json` (same-day backups overwrite
  /// that day's file), then keeps only the newest [maxBackups].
  Future<BackupFile> upload(
    http.Client client,
    BackupSnapshot snapshot, {
    required DateTime now,
  }) => _guard(() async {
    final api = drive.DriveApi(client);
    final name = BackupFileName.forDate(now);
    final existing = await _listBackups(api);
    final sameDay = existing.where((f) => f.name == name).firstOrNull;

    final bytes = utf8.encode(snapshot.toJson());
    final media = drive.Media(
      Stream.value(bytes),
      bytes.length,
      contentType: 'application/json',
    );
    const fields = 'id,name,modifiedTime';
    final saved = sameDay == null
        ? await api.files.create(
            drive.File(name: name, parents: [_space]),
            uploadMedia: media,
            $fields: fields,
          )
        : await api.files.update(
            drive.File(),
            sameDay.id,
            uploadMedia: media,
            $fields: fields,
          );

    final file =
        BackupFile.tryParse(
          id: saved.id,
          name: saved.name,
          modifiedTime: saved.modifiedTime,
        ) ??
        BackupFile(id: saved.id ?? '', name: name, backupDate: now);

    await _prune(api, [...existing.where((f) => f.id != file.id), file]);
    return file;
  });

  /// The newest backup, or null when the account has none.
  Future<BackupFile?> findLatest(http.Client client) => _guard(() async {
    final files = await _listBackups(drive.DriveApi(client));
    return BackupFile.newestFirst(files).firstOrNull;
  });

  Future<BackupSnapshot> download(http.Client client, BackupFile file) =>
      _guard(() async {
        final media =
            await drive.DriveApi(client).files.get(
                  file.id,
                  downloadOptions: drive.DownloadOptions.fullMedia,
                )
                as drive.Media;
        final json = await utf8.decodeStream(media.stream);
        return BackupSnapshot.fromJson(json);
      });

  Future<List<BackupFile>> _listBackups(drive.DriveApi api) async {
    final result = await api.files.list(
      spaces: _space,
      q: "name contains '${BackupFileName.prefix}' and trashed = false",
      $fields: 'files(id,name,modifiedTime)',
      pageSize: 100,
    );
    return [
      for (final f in result.files ?? const <drive.File>[])
        ?BackupFile.tryParse(
          id: f.id,
          name: f.name,
          modifiedTime: f.modifiedTime,
        ),
    ];
  }

  Future<void> _prune(drive.DriveApi api, List<BackupFile> files) async {
    for (final old in BackupFile.outdated(files, keep: maxBackups)) {
      await api.files.delete(old.id);
    }
  }

  /// Applies a timeout and normalises every error to [BackupException].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(_timeout);
    } catch (error) {
      throw BackupException.from(error);
    }
  }
}
