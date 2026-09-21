import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../viewmodels/backup_view_model.dart';
import '../backup_dialogs.dart';

/// Daily 12:00 AM auto-backup switch. Needs an account first.
class AutoBackupTile extends StatelessWidget {
  const AutoBackupTile({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BackupViewModel>();
    final enabled = vm.hasAccount;
    final radius = BorderRadius.circular(AppTheme.cardRadius);

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: enabled ? () => _toggle(context, !vm.autoBackupEnabled) : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, color: AppColors.green),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Backup Harian',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Senyap, setiap hari sekitar 12:00 AM · perlu internet',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: vm.autoBackupEnabled,
                  onChanged: enabled
                      ? (value) => _toggle(context, value)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggle(BuildContext context, bool value) async {
    final failure = await context.read<BackupViewModel>().setAutoBackup(
      enabled: value,
    );
    if (failure != null && context.mounted) {
      await presentBackupResult(context, failure);
    }
  }
}
