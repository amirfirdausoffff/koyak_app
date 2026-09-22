import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/month_report.dart';
import '../../models/year_month.dart';
import '../../viewmodels/history_view_model.dart';
import '../analytics/widgets/category_bar_chart.dart';
import '../analytics/widgets/category_breakdown_list.dart';
import '../analytics/widgets/income_split_bar.dart';
import '../dashboard/widgets/stat_grid.dart';
import '../debt/widgets/debt_status_row.dart';
import '../expense/widgets/expense_timeline.dart';
import '../shared/widgets/section_card.dart';

/// Read-only report of one finished month.
class MonthDetailView extends StatelessWidget {
  const MonthDetailView({super.key, required this.month});

  final YearMonth month;

  static Future<void> open(BuildContext context, YearMonth month) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => MonthDetailView(month: month)),
      );

  @override
  Widget build(BuildContext context) {
    final report = context.watch<HistoryViewModel>().reportFor(month);
    final summary = report.summary;

    return Scaffold(
      appBar: AppBar(title: Text(DateFormatter.month(month.start))),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _ClosingBalance(report: report),
            const SizedBox(height: 12),
            StatGrid(
              tiles: [
                StatTileData(
                  label: 'Duit',
                  amount: summary.totalIncome,
                  caption: '${report.incomes.length} sumber',
                  icon: Icons.account_balance_wallet_outlined,
                ),
                StatTileData(
                  label: 'Hutang',
                  amount: summary.totalDebt,
                  caption:
                      '${report.paidDebtCount}/${report.debts.length} dibayar',
                  icon: Icons.receipt_long_outlined,
                ),
                StatTileData(
                  label: 'Belanja',
                  amount: summary.totalExpense,
                  caption: '${report.expenseCount} transaksi',
                  icon: Icons.payments_outlined,
                ),
              ],
            ),
            if (summary.available > 0) ...[
              const SizedBox(height: 12),
              SectionCard(
                title: 'Pecahan Duit',
                child: IncomeSplitBar(summary: summary),
              ),
            ],
            if (report.categoryShares.isNotEmpty) ...[
              const SizedBox(height: 12),
              SectionCard(
                title: 'Belanja Ikut Kategori',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CategoryBarChart(shares: report.categoryShares),
                    const SizedBox(height: 12),
                    CategoryBreakdownList(shares: report.categoryShares),
                  ],
                ),
              ),
            ],
            if (report.debts.isNotEmpty) ...[
              const SizedBox(height: 12),
              SectionCard(
                title: 'Hutang',
                child: Column(
                  children: [
                    for (final status in report.debts)
                      DebtStatusRow(status: status, month: month),
                  ],
                ),
              ),
            ],
            if (report.overdue.isNotEmpty) ...[
              const SizedBox(height: 12),
              SectionCard(
                title: 'Tertunggak',
                child: Column(
                  children: [
                    for (final status in report.overdue)
                      DebtStatusRow(status: status, month: month),
                  ],
                ),
              ),
            ],
            if (report.incomes.isNotEmpty) ...[
              const SizedBox(height: 12),
              SectionCard(
                title: 'Sumber Duit',
                child: Column(
                  children: [
                    for (final income in report.incomes)
                      _AmountRow(
                        title: income.source,
                        subtitle: DateFormatter.full(income.date),
                        amount: income.amount,
                      ),
                  ],
                ),
              ),
            ],
            if (report.timeline.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Log Belanja',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ExpenseTimeline(groups: report.timeline, editable: false),
            ],
          ],
        ),
      ),
    );
  }
}

class _ClosingBalance extends StatelessWidget {
  const _ClosingBalance({required this.report});

  final MonthReport report;

  @override
  Widget build(BuildContext context) {
    final summary = report.summary;
    final color = summary.isKoyak ? AppColors.amber : AppColors.green;
    return SectionCard(
      borderColor: summary.isKoyak
          ? AppColors.amber.withValues(alpha: 0.5)
          : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Baki Akhir Bulan',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          if (summary.carriedForward != 0)
            Text(
              'Mula bulan dengan baki ${summary.carriedForward.asRinggit}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              summary.netRemaining.asRinggit,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            summary.isKoyak
                ? 'Bulan ni KOYAK — belanja lebih dari duit yang ada.'
                : 'Steady. Baki ni dibawa ke bulan depan.',
            style: TextStyle(
              fontSize: 12,
              color: summary.isKoyak ? AppColors.amber : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  final String title;
  final String subtitle;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount.asRinggit,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
