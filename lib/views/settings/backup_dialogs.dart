import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/errors/backup_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/backup_file.dart';
import '../../models/backup_result.dart';
import '../../viewmodels/backup_view_model.dart';
import '../shared/widgets/koyak_dialog.dart';
import '../shared/widgets/koyak_snack.dart';

/// Shows [result] to the user; a found backup is confirmed before loading.
Future<void> presentBackupResult(
  BuildContext context,
  BackupResult result,
) async {
  switch (result) {
    case BackupUploaded(:final file):
      showKoyakSnack(context, 'Backup berjaya · ${file.name}');
    case BackupRestored(:final file, :final recordCount):
      showKoyakSnack(
        context,
        'Backup ${file.name} dimuatkan · $recordCount rekod',
      );
    case NoBackupFound(:final email):
      await _showNoBackupDialog(context, email);
    case BackupAvailable(:final file):
      final confirmed = await _confirmRestore(context, file);
      if (!confirmed || !context.mounted) return;
      final restored = await context.read<BackupViewModel>().restore(file);
      if (context.mounted) await presentBackupResult(context, restored);
    case BackupFailed(:final failure):
      if (failure != BackupFailure.cancelled) {
        showKoyakSnack(context, failure.message);
      }
  }
}

Future<bool> confirmDisconnect(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => KoyakDialog(
      icon: Icons.link_off_rounded,
      accent: AppColors.amber,
      title: 'Putuskan Akaun?',
      message:
          'Auto-backup akan dimatikan. Fail backup dalam Google Drive '
          'tak dipadam.',
      primaryLabel: 'Putuskan',
      onPrimary: () => Navigator.of(dialogContext).pop(true),
    ),
  );
  return confirmed ?? false;
}

Future<void> _showNoBackupDialog(BuildContext context, String email) =>
    showDialog<void>(
      context: context,
      builder: (dialogContext) => KoyakDialog(
        icon: Icons.cloud_off_rounded,
        title: 'Tiada Backup',
        message:
            'Tiada fail backup Koyak ditemui untuk akaun $email. '
            'Profil baharu telah disediakan.',
        primaryLabel: 'OK',
        secondaryLabel: null,
        onPrimary: () => Navigator.of(dialogContext).pop(),
      ),
    );

Future<bool> _confirmRestore(BuildContext context, BackupFile file) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => KoyakDialog(
      icon: Icons.cloud_download_rounded,
      accent: AppColors.amber,
      title: 'Load Backup?',
      message: 'Data dalam phone ni akan diganti dengan backup terbaru.',
      content: _BackupFileTile(file: file),
      primaryLabel: 'Load',
      onPrimary: () => Navigator.of(dialogContext).pop(true),
    ),
  );
  return confirmed ?? false;
}

class _BackupFileTile extends StatelessWidget {
  const _BackupFileTile({required this.file});

  final BackupFile file;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(
              Icons.description_outlined,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormatter.stamp(file.takenAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
