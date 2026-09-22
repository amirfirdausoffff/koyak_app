import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/percent_formatter.dart';
import '../../../models/cashflow_summary.dart';

/// Part-to-whole of the money available this month (carried baki + pay):
/// Hutang | Belanja | Baki as one stacked bar.
class IncomeSplitBar extends StatelessWidget {
  const IncomeSplitBar({super.key, required this.summary});

  final CashflowSummary summary;

  static const _barHeight = 14.0;
  static const _segmentGap = 2.0;

  @override
  Widget build(BuildContext context) {
    final segments = [
      _Segment('Hutang', summary.totalDebt, AppColors.seriesDebt),
      _Segment('Belanja', summary.totalExpense, AppColors.seriesExpense),
      _Segment(
        'Baki',
        math.max(summary.netRemaining, 0),
        AppColors.seriesRemaining,
      ),
    ];
    final available = summary.available;
    // When overspent the bar represents total outflow, not what was there.
    final scale = math.max(available, summary.totalDebt + summary.totalExpense);
    final visible = segments.where((s) => s.amount > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: _barHeight,
            child: Row(
              children: [
                for (final (index, segment) in visible.indexed) ...[
                  if (index > 0) const SizedBox(width: _segmentGap),
                  Expanded(
                    flex: math.max(1, (segment.amount / scale * 1000).round()),
                    child: ColoredBox(color: segment.color),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final segment in segments)
          _LegendRow(
            segment: segment,
            percentage: segment.amount / available * 100,
          ),
        if (summary.carriedForward != 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Duit ada ${available.asRinggit} = duit masuk '
              '${summary.totalIncome.asRinggit} + baki bulan lepas '
              '${summary.carriedForward.asRinggit}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
        if (summary.isKoyak)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: AppColors.amber,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Terlebih ${summary.netRemaining.abs().asRinggit} '
                    'daripada duit yang ada',
                    style: const TextStyle(color: AppColors.amber),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Segment {
  const _Segment(this.label, this.amount, this.color);

  final String label;
  final double amount;
  final Color color;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.segment, required this.percentage});

  final _Segment segment;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: segment.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            segment.label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            segment.amount.asRinggit,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(
            width: 52,
            child: Text(
              PercentFormatter.format(percentage),
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
