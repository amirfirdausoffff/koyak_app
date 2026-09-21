import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/month_report.dart';
import '../../viewmodels/history_view_model.dart';
import 'month_detail_view.dart';

/// Finished months, newest first. Tap one for its full detail.
class MonthHistoryList extends StatelessWidget {
  const MonthHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final months = context.watch<HistoryViewModel>().pastMonths;
    if (months.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Sejarah muncul sendiri bila masuk bulan baru. Data bulan ni '
          'takkan hilang.',
          style: TextStyle(color: AppColors.textMuted, height: 1.45),
        ),
      );
    }
    return Column(
      children: [
        for (final (index, overview) in months.indexed) ...[
          if (index > 0) const SizedBox(height: 8),
          _MonthRow(overview: overview),
        ],
      ],
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.overview});

  final MonthOverview overview;

  @override
  Widget build(BuildContext context) {
    final summary = overview.summary;
    final radius = BorderRadius.circular(16);
    return Material(
      color: AppColors.surfaceRaised,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: () => MonthDetailView.open(context, overview.month),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormatter.month(overview.month.start),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Belanja ${summary.totalExpense.asRinggit}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Baki',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  Text(
                    summary.netRemaining.asRinggit,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: summary.isKoyak
                          ? AppColors.amber
                          : AppColors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
