import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// App dialog: icon badge, centred title and message, optional [content],
/// then a Batal / primary button pair spanning the full width. Pass a null
/// [secondaryLabel] for a single-button notice.
class KoyakDialog extends StatelessWidget {
  const KoyakDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.primaryLabel,
    required this.onPrimary,
    this.message,
    this.content,
    this.secondaryLabel = 'Batal',
    this.onSecondary,
    this.accent = AppColors.green,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? content;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;

  /// Defaults to closing the dialog.
  final VoidCallback? onSecondary;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final message = this.message;
    final content = this.content;

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: _IconBadge(icon: icon, color: accent),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
            if (content != null) ...[const SizedBox(height: 20), content],
            const SizedBox(height: 24),
            Row(
              children: [
                if (secondaryLabel case final label?) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          onSecondary ?? () => Navigator.of(context).pop(),
                      child: Text(label),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: onPrimary,
                    style: FilledButton.styleFrom(backgroundColor: accent),
                    child: Text(primaryLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1.5),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}
