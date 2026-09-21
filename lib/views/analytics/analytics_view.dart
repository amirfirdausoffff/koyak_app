import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../viewmodels/cashflow_view_model.dart';
import '../../viewmodels/expense_view_model.dart';
import '../history/month_history_list.dart';
import '../shared/widgets/page_header.dart';
import '../shared/widgets/section_card.dart';
import 'widgets/category_bar_chart.dart';
import 'widgets/category_breakdown_list.dart';
import 'widgets/income_split_bar.dart';

/// "Duit Habis Ke Mana?"
class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final summary = context.watch<CashflowViewModel>().summary;
    final shares = context.watch<ExpenseViewModel>().categoryBreakdown;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          PageHeader(
            title: 'Duit Habis Ke Mana?',
            subtitle: DateFormatter.month(DateTime.now()),
          ),
          SectionCard(
            title: 'Pecahan Duit',
            trailing: summary.available > 0
                ? Text(
                    summary.available.asRinggit,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  )
                : null,
            child: summary.available > 0
                ? IncomeSplitBar(summary: summary)
                : const _Hint('Masukkan gaji dulu untuk tengok pecahan.'),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Belanja Ikut Kategori',
            trailing: shares.isEmpty
                ? null
                : Text(
                    summary.totalExpense.asRinggit,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
            child: shares.isEmpty
                ? const _Hint('Belum ada belanja bulan ni.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CategoryBarChart(shares: shares),
                      const SizedBox(height: 12),
                      CategoryBreakdownList(shares: shares),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          const SectionCard(
            title: 'Sejarah Bulanan',
            child: MonthHistoryList(),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: const TextStyle(color: AppColors.textMuted)),
    );
  }
}
