import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../viewmodels/backup_view_model.dart';
import '../../shared/widgets/section_card.dart';
import '../backup_dialogs.dart';
import 'busy_label.dart';

/// Which Google account backups go to, with pick / switch / disconnect.
class BackupAccountCard extends StatelessWidget {
  const BackupAccountCard({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BackupViewModel>();
    final email = vm.accountEmail;
    final connecting = vm.task == BackupTask.connecting;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Avatar(email: email),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email == null ? 'Belum pilih akaun' : 'Akaun backup',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email ?? 'Pilih akaun Google dalam phone ni',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (email == null)
            FilledButton(
              onPressed: vm.isBusy ? null : () => _connect(context),
              child: BusyLabel(
                busy: connecting,
                icon: Icons.account_circle_outlined,
                label: 'Pilih Akaun Google',
                busyLabel: 'Menyambung...',
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: vm.isBusy ? null : () => _connect(context),
                    child: BusyLabel(
                      busy: connecting,
                      icon: Icons.swap_horiz_rounded,
                      label: 'Tukar',
                      busyLabel: 'Menyambung...',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: vm.isBusy ? null : () => _disconnect(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.amber,
                    ),
                    icon: const Icon(Icons.link_off_rounded, size: 18),
                    label: const Text('Putuskan'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _connect(BuildContext context) async {
    final result = await context.read<BackupViewModel>().connectAccount();
    if (context.mounted) await presentBackupResult(context, result);
  }

  Future<void> _disconnect(BuildContext context) async {
    if (!await confirmDisconnect(context) || !context.mounted) return;
    await context.read<BackupViewModel>().disconnect();
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    final email = this.email;
    final color = email == null ? AppColors.textMuted : AppColors.green;
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: email == null
          ? Icon(Icons.cloud_off_rounded, color: color, size: 22)
          : Text(
              email.characters.first.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}
