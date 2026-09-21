import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import 'koyak_dialog.dart';

/// Asks before saving; [summary] shows exactly what will be stored.
Future<bool> confirmSave(
  BuildContext context, {
  required String title,
  required Widget summary,
  String confirmLabel = 'Simpan',
}) => _confirm(
  context,
  icon: Icons.check_rounded,
  accent: AppColors.green,
  title: title,
  message: 'Semak dulu sebelum simpan.',
  summary: summary,
  confirmLabel: confirmLabel,
);

/// Asks before deleting [itemName]. [message] can explain side effects.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String itemName,
  String? message,
  Widget? summary,
}) => _confirm(
  context,
  icon: Icons.delete_outline_rounded,
  accent: AppColors.amber,
  title: title,
  message: message ?? '"$itemName" akan dipadam.',
  summary: summary,
  confirmLabel: 'Padam',
);

Future<bool> _confirm(
  BuildContext context, {
  required IconData icon,
  required Color accent,
  required String title,
  required String message,
  required String confirmLabel,
  Widget? summary,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => KoyakDialog(
      icon: icon,
      accent: accent,
      title: title,
      message: message,
      content: summary,
      primaryLabel: confirmLabel,
      onPrimary: () => Navigator.of(dialogContext).pop(true),
      onSecondary: () => Navigator.of(dialogContext).pop(false),
    ),
  );
  return confirmed ?? false;
}

/// One-line recap of a record: icon, name, detail and amount.
class ConfirmSummary extends StatelessWidget {
  const ConfirmSummary({
    super.key,
    required this.icon,
    required this.title,
    required this.amount,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              amount.asRinggit,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
