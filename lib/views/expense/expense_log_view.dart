import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/expense_day_group.dart';
import '../../viewmodels/expense_view_model.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/koyak_snack.dart';
import '../shared/widgets/page_header.dart';
import '../shared/widgets/section_card.dart';
import 'expense_history_view.dart';
import 'widgets/expense_timeline.dart';
import 'widgets/quick_expense_form.dart';

class ExpenseLogView extends StatelessWidget {
  const ExpenseLogView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExpenseViewModel>();
    final timeline = vm.timeline;
    final recentTimeline = _takeRecent(timeline, 5);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          PageHeader(
            title: 'Belanja',
            subtitle: 'Catat pantas. Tak sampai 3 saat.',
            trailing: IconButton(
              onPressed: () => ExpenseHistoryView.open(context),
              tooltip: 'Sejarah belanja',
              icon: const Icon(
                Icons.calendar_month_outlined,
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
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sejarah Belanja',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormatter.month(vm.currentMonth.start)} · '
                      '${vm.expenses.length} transaksi',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (timeline.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Belum ada belanja bulan ni',
              message: 'Setiap ringgit yang keluar, catat kat atas.',
            )
          else
            ExpenseTimeline(groups: recentTimeline, showDayTotal: false),
          if (timeline.isNotEmpty) ...[
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () => ExpenseHistoryView.open(context),
              icon: const Icon(Icons.history_rounded),
              label: const Text('Lihat sejarah penuh'),
            ),
          ],
        ],
      ),
    );
  }
}

List<ExpenseDayGroup> _takeRecent(
  List<ExpenseDayGroup> groups,
  int limit,
) {
  var remaining = limit;
  final result = <ExpenseDayGroup>[];
  for (final group in groups) {
    if (remaining == 0) break;
    final expenses = group.expenses.take(remaining).toList();
    if (expenses.isEmpty) continue;
    result.add(ExpenseDayGroup(day: group.day, expenses: expenses));
    remaining -= expenses.length;
  }
  return result;
}
