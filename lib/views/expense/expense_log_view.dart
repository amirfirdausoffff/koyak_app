import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../viewmodels/expense_view_model.dart';
import '../history/history_view.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/koyak_snack.dart';
import '../shared/widgets/page_header.dart';
import '../shared/widgets/section_card.dart';
import 'widgets/expense_timeline.dart';
import 'widgets/quick_expense_form.dart';

class ExpenseLogView extends StatelessWidget {
  const ExpenseLogView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExpenseViewModel>();
    final timeline = vm.timeline;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          PageHeader(
            title: 'Belanja',
            subtitle: 'Catat pantas. Tak sampai 3 saat.',
            trailing: IconButton(
              onPressed: () => HistoryView.open(context),
              tooltip: 'Sejarah bulanan',
              icon: const Icon(
                Icons.history_rounded,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SectionCard(
            child: QuickExpenseForm(
              onSaved: (expense) {
                FocusScope.of(context).unfocus();
                showKoyakSnack(
                  context,
                  '${expense.amount.asRinggit} · ${expense.title} dicatat',
                  onUndo: () => vm.remove(expense.id),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(label: 'Hari ni', amount: vm.todayTotal),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(label: 'Bulan ni', amount: vm.total),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (timeline.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Belum ada belanja bulan ni',
              message: 'Setiap ringgit yang keluar, catat kat atas.',
            )
          else
            ExpenseTimeline(groups: timeline),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Text(
              amount.asRinggit,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
