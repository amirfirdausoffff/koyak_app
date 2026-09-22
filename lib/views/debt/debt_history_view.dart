import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/debt_model.dart';
import '../../models/month_report.dart';
import '../../viewmodels/debt_view_model.dart';
import '../shared/widgets/category_tag.dart';
import '../shared/widgets/section_card.dart';
import 'widgets/debt_status_row.dart';

/// Debts month by month, plus the ones that are done.
class DebtHistoryView extends StatelessWidget {
  const DebtHistoryView({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const DebtHistoryView()));

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DebtViewModel>();
    final months = vm.pastMonths;
    final finished = vm.finished;

    return Scaffold(
      appBar: AppBar(title: const Text('Sejarah Hutang')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (months.isEmpty && finished.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Sejarah muncul sendiri bila masuk bulan baru. Rekod hutang '
                  'bulan ni takkan hilang.',
                  style: TextStyle(color: AppColors.textMuted, height: 1.45),
                ),
              ),
            for (final month in months) ...[
              _DebtMonthCard(debts: vm.monthOf(month)),
              const SizedBox(height: 12),
            ],
            if (finished.isNotEmpty)
              SectionCard(
                title: 'Hutang Selesai',
                child: Column(
                  children: [
                    for (final debt in finished) _FinishedRow(debt: debt),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DebtMonthCard extends StatelessWidget {
  const _DebtMonthCard({required this.debts});

  final DebtMonth debts;

  @override
  Widget build(BuildContext context) {
    final month = debts.month;
    return SectionCard(
      title: DateFormatter.month(month.start),
      trailing: debts.debts.isEmpty
          ? null
          : Text(
              '${debts.paidCount}/${debts.debts.length} dibayar',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (debts.debts.isNotEmpty) ...[
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: debts.paidTotal.asRinggit,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: '  / ${debts.total.asRinggit}',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            for (final status in debts.debts)
              DebtStatusRow(status: status, month: month),
          ],
          if (debts.overdue.isNotEmpty) ...[
            if (debts.debts.isNotEmpty) const SizedBox(height: 8),
            const Text(
              'Tertunggak',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            for (final status in debts.overdue)
              DebtStatusRow(status: status, month: month),
          ],
        ],
      ),
    );
  }
}

/// A debt that's off the list: why, and how much went into it.
class _FinishedRow extends StatelessWidget {
  const _FinishedRow({required this.debt});

  final DebtModel debt;

  @override
  Widget build(BuildContext context) {
    final removed = debt.endedAt != null && debt.paidMonth == null;
    final scheduled = debt.scheduledPayments;
    final label = [
      _reason,
      if (scheduled != null) '${debt.payments.length}/$scheduled bayaran',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            removed ? Icons.remove_circle_outline : Icons.flag_rounded,
            size: 20,
            color: removed ? AppColors.textMuted : AppColors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    CategoryTag(category: debt.category),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Dibayar',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              Text(
                debt.totalPaid.asRinggit,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _reason {
    if (debt.paidMonth case final paid?) {
      return 'Dibayar ${DateFormatter.monthYearShort(paid.start)}';
    }
    if (debt.endedAt case final ended?) {
      return 'Dipadam ${DateFormatter.monthYearShort(ended)}';
    }
    if (debt.lastMonth case final last?) {
      return 'Tamat ${DateFormatter.monthYearShort(last.start)}';
    }
    return 'Selesai';
  }
}
