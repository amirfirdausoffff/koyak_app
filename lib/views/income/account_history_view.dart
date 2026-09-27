import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/expense_model.dart';
import '../../models/income_model.dart';
import '../../models/year_month.dart';
import '../../viewmodels/expense_view_model.dart';
import '../../viewmodels/income_view_model.dart';
import '../shared/category_style.dart';
import 'income_edit_sheet.dart';

/// Account-level history. Starts with the current month and reveals more rows
/// as the user scrolls, keeping a busy account easy to scan.
class AccountHistoryView extends StatefulWidget {
  const AccountHistoryView({super.key, required this.account});

  final IncomeModel account;

  static Future<void> open(BuildContext context, IncomeModel account) =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AccountHistoryView(account: account),
        ),
      );

  @override
  State<AccountHistoryView> createState() => _AccountHistoryViewState();
}

class _AccountHistoryViewState extends State<AccountHistoryView> {
  static const _pageSize = 10;
  late YearMonth _month;
  final _scroll = ScrollController();
  int _visible = _pageSize;

  @override
  void initState() {
    super.initState();
    _month = context.read<IncomeViewModel>().currentMonth;
    _scroll.addListener(_loadMore);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_loadMore)
      ..dispose();
    super.dispose();
  }

  void _loadMore() {
    if (_scroll.position.extentAfter > 180) return;
    setState(() => _visible += _pageSize);
  }

  void _changeMonth(YearMonth month) => setState(() {
    _month = month;
    _visible = _pageSize;
  });

  @override
  Widget build(BuildContext context) {
    final incomes = context.watch<IncomeViewModel>();
    final expenses = context.watch<ExpenseViewModel>();
    final account =
        incomes.sourceNamed(widget.account.source) ?? widget.account;
    final spent = expenses.totalFromAccount(account.source);
    final activities = <_AccountActivity>[
      for (final income in incomes.recordsForSource(account.source))
        for (final entry in income.historyEntries)
          if (_month.contains(entry.date))
            _AccountActivity.deposit(entry.amount, entry.date),
      for (final expense in expenses.expensesIn(_month))
        if (expense.account.toLowerCase() == account.source.toLowerCase())
          _AccountActivity.expense(expense.amount, expense.title, expense.date),
    ]..sort((a, b) => b.date.compareTo(a.date));
    final shown = activities.take(_visible).toList();
    final isCurrent = _month == incomes.currentMonth;

    return Scaffold(
      appBar: AppBar(
        title: Text(account.source),
        actions: [
          IconButton(
            tooltip: 'Kemaskini akaun',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                showIncomeEditSheet(context, account, spent: spent),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _BalanceCard(
              balance: account.amount - spent,
              deposited: account.historyEntries.fold(
                0.0,
                (sum, entry) => sum + entry.amount,
              ),
              spent: spent,
            ),
            const SizedBox(height: 20),
            _MonthPicker(
              month: _month,
              canGoNext: !isCurrent,
              onPrevious: () => _changeMonth(_month.previous),
              onNext: isCurrent ? null : () => _changeMonth(_month.next),
            ),
            const SizedBox(height: 16),
            Text(
              'Sejarah akaun',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              '${activities.length} transaksi bulan ini',
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            if (shown.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Text(
                    'Tiada transaksi untuk bulan ini.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              )
            else
              for (final activity in shown) _ActivityTile(activity: activity),
            if (shown.length < activities.length)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.deposited,
    required this.spent,
  });
  final double balance;
  final double deposited;
  final double spent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.surfaceRaised,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Baki semasa', style: TextStyle(color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          balance.asRinggit,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'Duit masuk',
                amount: deposited,
                color: AppColors.green,
              ),
            ),
            Expanded(
              child: _Stat(
                label: 'Dibelanja',
                amount: spent,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.amount, required this.color});
  final String label;
  final double amount;
  final Color color;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
      Text(
        amount.asRinggit,
        style: TextStyle(fontWeight: FontWeight.w700, color: color),
      ),
    ],
  );
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({
    required this.month,
    required this.canGoNext,
    required this.onPrevious,
    this.onNext,
  });
  final YearMonth month;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        onPressed: onPrevious,
        icon: const Icon(Icons.chevron_left_rounded),
      ),
      Expanded(
        child: Center(
          child: Text(
            DateFormatter.month(month.start),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      IconButton(
        onPressed: canGoNext ? onNext : null,
        icon: const Icon(Icons.chevron_right_rounded),
      ),
    ],
  );
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});
  final _AccountActivity activity;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
      ),
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
              activity.isDeposit
                  ? Icons.add_rounded
                  : ExpenseCategory.lainLain.icon,
              color: activity.isDeposit
                  ? AppColors.green
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  DateFormatter.stamp(activity.date),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${activity.isDeposit ? '+' : '-'} ${activity.amount.asRinggit}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: activity.isDeposit ? AppColors.green : null,
            ),
          ),
        ],
      ),
    ),
  );
}

class _AccountActivity {
  const _AccountActivity._(this.amount, this.title, this.date, this.isDeposit);
  factory _AccountActivity.deposit(double amount, DateTime date) =>
      _AccountActivity._(amount, 'Duit masuk', date, true);
  factory _AccountActivity.expense(
    double amount,
    String title,
    DateTime date,
  ) => _AccountActivity._(amount, title, date, false);
  final double amount;
  final String title;
  final DateTime date;
  final bool isDeposit;
}
