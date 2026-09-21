import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';

/// Wordmark + slogan on the left, settings on the right, vertically centred.
class DashboardHeader extends StatelessWidget {
  static const _wordmarkSpacing = -0.4;

  const DashboardHeader({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Letter spacing is applied half before each glyph, which
              // would shift the wordmark off the slogan's left edge.
              Transform.translate(
                offset: const Offset(-_wordmarkSpacing / 2, 0),
                child: const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 26,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: _wordmarkSpacing,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.slogan,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: onOpenSettings,
          tooltip: 'Tetapan & backup',
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.border),
            fixedSize: const Size.square(44),
          ),
          icon: const Icon(
            Icons.settings_outlined,
            size: 20,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Today's date and how many days the month has left (today included).
class TodayCard extends StatelessWidget {
  const TodayCard({super.key, required this.daysRemaining});

  final int daysRemaining;

  @override
  Widget build(BuildContext context) {
    final isLastDay = daysRemaining <= 1;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.today_rounded,
                size: 20,
                color: AppColors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hari ini',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormatter.longDay(DateTime.now()),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$daysRemaining',
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: isLastDay ? AppColors.amber : AppColors.textPrimary,
                  ),
                ),
                Text(
                  isLastDay ? 'hari terakhir' : 'hari lagi',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
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
