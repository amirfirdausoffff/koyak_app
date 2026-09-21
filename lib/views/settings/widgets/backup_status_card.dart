import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/backup_result.dart';
import '../../../viewmodels/backup_view_model.dart';
import '../../shared/widgets/section_card.dart';
import '../backup_dialogs.dart';
import 'busy_label.dart';

/// Last backup time plus the manual 'Backup Sekarang' and
/// 'Semak & Load Backup' actions.
class BackupStatusCard extends StatelessWidget {
  const BackupStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BackupViewModel>();
    final last = vm.lastBackupAt;
    final canAct = vm.hasAccount && !vm.isBusy;
    final checking =
        vm.task == BackupTask.checking || vm.task == BackupTask.restoring;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 8),
              Text(
                'Backup terakhir',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            last == null ? 'Belum pernah backup' : DateFormatter.stamp(last),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: last == null ? AppColors.textMuted : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: canAct ? () => _run(context, vm.backupNow) : null,
            child: BusyLabel(
              busy: vm.task == BackupTask.backingUp,
              icon: Icons.cloud_upload_outlined,
              label: 'Backup Sekarang',
              busyLabel: 'Tengah backup...',
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: canAct ? () => _run(context, vm.checkForBackup) : null,
            child: BusyLabel(
              busy: checking,
              icon: Icons.cloud_download_outlined,
              label: 'Semak & Load Backup',
              busyLabel: vm.task == BackupTask.restoring
                  ? 'Tengah load...'
                  : 'Tengah semak...',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<BackupResult> Function() action,
  ) async {
    final result = await action();
    if (context.mounted) await presentBackupResult(context, result);
  }
}
