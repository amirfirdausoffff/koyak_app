import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/expense_day_group.dart';
import '../../../models/expense_model.dart';
import '../../../viewmodels/expense_view_model.dart';
import '../../shared/category_style.dart';
import '../../shared/widgets/confirm_dialogs.dart';
import '../../shared/widgets/koyak_snack.dart';

/// Expenses grouped by day, newest first. Swipe-to-delete unless
/// [editable] is false (history).
class ExpenseTimeline extends StatelessWidget {
  const ExpenseTimeline({
    super.key,
    required this.groups,
    this.editable = true,
    this.showDayTotal = true,
  });

  final List<ExpenseDayGroup> groups;
  final bool editable;
  final bool showDayTotal;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final group in groups) ...[
          _DayHeader(
            label: DateFormatter.relativeDay(group.day, now),
            total: showDayTotal ? group.total : null,
          ),
          for (final (index, expense) in group.expenses.indexed)
            _TimelineExpense(
              key: ValueKey(expense.id),
              expense: expense,
              editable: editable,
              highlighted: index == 0,
            ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

class _TimelineExpense extends StatelessWidget {
  const _TimelineExpense({
    super.key,
    required this.expense,
    required this.editable,
    required this.highlighted,
  });

  final ExpenseModel expense;
  final bool editable;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final tile = editable
        ? _DismissibleExpenseTile(expense: expense)
        : _ExpenseRow(expense: expense);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 18,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Positioned(
                  top: 0,
                  bottom: 0,
                  child: VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.border,
                  ),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: highlighted
                        ? AppColors.green
                        : AppColors.textMuted,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: tile),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label, required this.total});

  final String label;
  final double? total;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label, style: style?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          if (total case final amount?)
            Text(
              amount.asRinggit,
              style: style?.copyWith(color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _DismissibleExpenseTile extends StatelessWidget {
  const _DismissibleExpenseTile({required this.expense});

  final ExpenseModel expense;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ExpenseViewModel>();
    return Dismissible(
      key: ValueKey('expense-${expense.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.amber),
      ),
      confirmDismiss: (_) => confirmDelete(
        context,
        title: 'Padam Belanja?',
        itemName: expense.title,
        summary: ConfirmSummary(
          icon: expense.category.icon,
          title: expense.title,
          subtitle:
              '${expense.category.label} · '
              '${expense.account.isEmpty ? 'Akaun tidak direkod' : expense.account} · '
              '${DateFormatter.relativeDay(expense.date, DateTime.now())}',
          amount: expense.amount,
        ),
      ),
      onDismissed: (_) {
        vm.remove(expense.id);
        showKoyakSnack(
          context,
          '"${expense.title}" dipadam',
          onUndo: () => vm.upsert(expense),
        );
      },
      child: _ExpenseRow(expense: expense),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense});

  final ExpenseModel expense;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              expense.category.icon,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${expense.category.label} · '
                  '${expense.account.isEmpty ? 'Akaun tidak direkod' : expense.account} · '
                  '${DateFormatter.time(expense.date)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            expense.amount.asRinggit,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
