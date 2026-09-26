import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/cashflow_summary.dart';

/// The one number the dashboard leads with: what is safe to spend.
class BalanceHero extends StatelessWidget {
  const BalanceHero({super.key, required this.summary});

  final CashflowSummary summary;

  @override
  Widget build(BuildContext context) {
    final isKoyak = summary.isKoyak;
    final color = isKoyak ? AppColors.amber : AppColors.green;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isKoyak ? 'Bajet Bulan Ini Defisit' : 'Boleh Belanja Lagi',
          style: textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${CurrencyFormatter.symbol} ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.75),
                  ),
                ),
                TextSpan(
                  text: CurrencyFormatter.formatNumber(
                    isKoyak ? summary.netRemaining.abs() : summary.netRemaining,
                  ),
                  style: TextStyle(
                    fontSize: 52,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isKoyak
              ? 'Komitmen dan belanja lebih ${summary.netRemaining.abs().asRinggit}. '
                    'Tahan belanja sampai duit masuk.'
              : _formulaCaption(),
          style: textTheme.bodySmall?.copyWith(
            color: isKoyak ? AppColors.amber : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  String _formulaCaption() {
    final flow =
        'Duit ${summary.cashOnHand.asRinggit} · Komitmen ${summary.totalDebt.asRinggit}';
    final carried = summary.carriedForward;
    if (carried == 0) return flow;
    final now = DateTime.now();
    final lastMonth = DateFormatter.monthName(
      DateTime(now.year, now.month - 1),
    );
    return '$flow · Termasuk baki $lastMonth ${carried.asRinggit}';
  }
}
