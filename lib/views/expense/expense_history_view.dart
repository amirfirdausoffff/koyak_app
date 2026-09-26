import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_helper.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/expense_day_group.dart';
import '../../models/expense_model.dart';
import '../../models/year_month.dart';
import '../../viewmodels/expense_view_model.dart';
import '../shared/category_style.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/section_card.dart';
import 'widgets/expense_timeline.dart';

class ExpenseHistoryView extends StatefulWidget {
  const ExpenseHistoryView({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const ExpenseHistoryView()),
  );

  @override
  State<ExpenseHistoryView> createState() => _ExpenseHistoryViewState();
}

class _ExpenseHistoryViewState extends State<ExpenseHistoryView> {
  final _search = TextEditingController();
  late YearMonth _month;
  ExpenseCategory? _category;

  @override
  void initState() {
    super.initState();
    _month = context.read<ExpenseViewModel>().currentMonth;
    _search.addListener(_refresh);
  }

  @override
  void dispose() {
    _search
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExpenseViewModel>();
    final monthExpenses = vm.expensesIn(_month);
    final categories = <ExpenseCategory>{
      for (final expense in monthExpenses) expense.category,
    }.toList()..sort((a, b) => a.label.compareTo(b.label));
    if (_category != null && !categories.contains(_category)) {
      _category = null;
    }

    final query = _search.text.trim().toLowerCase();
    final filtered = monthExpenses.where((expense) {
      final matchesCategory =
          _category == null || expense.category == _category;
      final haystack = [
        expense.title,
        expense.category.label,
        expense.account,
      ].join(' ').toLowerCase();
      return matchesCategory && (query.isEmpty || haystack.contains(query));
    }).toList();
    final timeline = _groupByDay(filtered);
    final breakdown = vm.categoryBreakdownFor(_month);
    final highest = breakdown.isEmpty ? null : breakdown.first;
    final isCurrentMonth = _month == vm.currentMonth;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sejarah Belanja'),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            _MonthPicker(
              month: _month,
              canGoNext: !isCurrentMonth,
              onPrevious: () => setState(() {
                _month = _month.previous;
                _category = null;
              }),
              onNext: isCurrentMonth
                  ? null
                  : () => setState(() {
                      _month = _month.next;
                      _category = null;
                    }),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _HistoryStat(
                    label: 'Jumlah belanja',
                    value: vm.totalIn(_month).asRinggit,
                    caption: '${monthExpenses.length} transaksi',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _HistoryStat(
                    label: 'Paling banyak',
                    value: highest?.category.label ?? '—',
                    caption: highest?.amount.asRinggit ?? 'Belum ada data',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('expense-history-search'),
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari nama, akaun atau kategori',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: _search.clear,
                        tooltip: 'Padam carian',
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Semua'),
                      selected: _category == null,
                      onSelected: (_) => setState(() => _category = null),
                    ),
                    for (final category in categories) ...[
                      const SizedBox(width: 8),
                      ChoiceChip(
                        avatar: Icon(category.icon, size: 17),
                        label: Text(category.label),
                        selected: _category == category,
                        onSelected: (_) =>
                            setState(() => _category = category),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            if (timeline.isEmpty)
              EmptyState(
                icon: query.isEmpty
                    ? Icons.receipt_long_outlined
                    : Icons.search_off_rounded,
                title: query.isEmpty
                    ? 'Belum ada belanja bulan ni'
                    : 'Belanja tak dijumpai',
                message: query.isEmpty
                    ? 'Pilih bulan lain atau mula catat belanja.'
                    : 'Cuba nama, akaun atau kategori lain.',
              )
            else
              ExpenseTimeline(groups: timeline, editable: false),
          ],
        ),
      ),
    );
  }
}

List<ExpenseDayGroup> _groupByDay(List<ExpenseModel> expenses) {
  final groups = <ExpenseDayGroup>[];
  for (final expense in expenses) {
    final day = DateHelper.dateOnly(expense.date);
    if (groups.isNotEmpty && groups.last.day == day) {
      groups.last.expenses.add(expense);
    } else {
      groups.add(ExpenseDayGroup(day: day, expenses: [expense]));
    }
  }
  return groups;
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({
    required this.month,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  final YearMonth month;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            tooltip: 'Bulan sebelumnya',
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  DateFormatter.month(month.start),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '1 ${DateFormatter.monthName(month.start)} – '
                  '${month.dayCount} ${DateFormatter.monthName(month.start)}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: canGoNext ? onNext : null,
            tooltip: 'Bulan seterusnya',
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _HistoryStat extends StatelessWidget {
  const _HistoryStat({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
