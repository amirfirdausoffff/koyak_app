import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/google_drive_backup_service.dart';
import 'widgets/auto_backup_tile.dart';
import 'widgets/backup_account_card.dart';
import 'widgets/backup_status_card.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const SettingsView()));

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Tetapan')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'BACKUP GOOGLE DRIVE',
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.green,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Percuma & peribadi. Backup disimpan dalam ruang tersembunyi '
              'Google Drive kau — fail lain dalam Drive tak terusik.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            const BackupAccountCard(),
            const SizedBox(height: 12),
            const AutoBackupTile(),
            const SizedBox(height: 12),
            const BackupStatusCard(),
            const SizedBox(height: 16),
            Text(
              'Hanya ${GoogleDriveBackupService.maxBackups} backup terbaru '
              'disimpan (koyak_DDMMYY.json). Yang lama dipadam automatik.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
