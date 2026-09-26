import '../core/utils/date_helper.dart';
import '../core/utils/id_generator.dart';
import '../models/category_share.dart';
import '../models/expense_day_group.dart';
import '../models/expense_model.dart';
import '../models/year_month.dart';
import 'persisted_list_view_model.dart';

/// Expenses are never cleared: each view shows one calendar month, so a new
/// month starts at RM 0.00 while old months stay in the history.
class ExpenseViewModel extends PersistedListViewModel<ExpenseModel> {
  ExpenseViewModel(super.repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  YearMonth get currentMonth => YearMonth.of(_clock());

  /// This month's expenses, newest first.
  List<ExpenseModel> get expenses => expensesIn(currentMonth);

  double get total => totalIn(currentMonth);

  List<ExpenseDayGroup> get timeline => timelineFor(currentMonth);

  List<CategoryShare> get categoryBreakdown =>
      categoryBreakdownFor(currentMonth);

  double get todayTotal {
    final now = _clock();
    return _sum(items.where((e) => DateHelper.isSameDay(e.date, now)));
  }

  Set<YearMonth> get monthsWithData => {
    for (final expense in items) YearMonth.of(expense.date),
  };

  List<ExpenseModel> expensesIn(YearMonth month) =>
      items.where((e) => month.contains(e.date)).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  double totalIn(YearMonth month) => _sum(expensesIn(month));

  /// Amount spent from [account] in [month].
  double totalFromAccount(String account, [YearMonth? month]) {
    final name = account.trim().toLowerCase();
    if (name.isEmpty) return 0;
    final expenses = month == null ? this.expenses : expensesIn(month);
    return _sum(
      expenses.where((expense) => expense.account.trim().toLowerCase() == name),
    );
  }

  /// [month]'s expenses bucketed per day, newest day first.
  List<ExpenseDayGroup> timelineFor(YearMonth month) {
    final groups = <ExpenseDayGroup>[];
    for (final expense in expensesIn(month)) {
      final day = DateHelper.dateOnly(expense.date);
      if (groups.isNotEmpty && groups.last.day == day) {
        groups.last.expenses.add(expense);
      } else {
        groups.add(ExpenseDayGroup(day: day, expenses: [expense]));
      }
    }
    return groups;
  }

  /// Spending per category in [month], biggest first.
  List<CategoryShare> categoryBreakdownFor(YearMonth month) {
    final expenses = expensesIn(month);
    final grandTotal = _sum(expenses);
    if (grandTotal <= 0) return const [];

    final totals = <ExpenseCategory, double>{};
    for (final e in expenses) {
      totals.update(e.category, (v) => v + e.amount, ifAbsent: () => e.amount);
    }
    return [
      for (final entry in totals.entries)
        CategoryShare(
          category: entry.key,
          amount: entry.value,
          percentage: entry.value / grandTotal * 100,
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
  }

  /// The title an expense is saved with: blank falls back to the category.
  static String resolveTitle(String title, ExpenseCategory category) {
    final name = title.trim();
    return name.isEmpty ? category.label : name;
  }

  /// Quick entry: a blank [title] falls back to the category name.
  Future<ExpenseModel> add({
    required double amount,
    required ExpenseCategory category,
    String account = '',
    String title = '',
  }) async {
    final expense = ExpenseModel(
      id: IdGenerator.next(),
      title: resolveTitle(title, category),
      amount: amount,
      category: category,
      date: _clock(),
      account: account.trim(),
    );
    await upsert(expense);
    return expense;
  }

  static double _sum(Iterable<ExpenseModel> expenses) =>
      expenses.fold(0, (sum, e) => sum + e.amount);
}
