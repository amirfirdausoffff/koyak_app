import '../core/utils/id_generator.dart';
import '../models/income_model.dart';
import '../models/year_month.dart';
import 'persisted_list_view_model.dart';

/// How an edit changes a money source's amount.
enum AmountChange {
  /// Top up: GX Bank RM 2 + RM 10 = RM 12.
  add,

  /// Set a new balance outright.
  replace;

  double apply(double current, double value) => switch (this) {
    AmountChange.add => current + value,
    AmountChange.replace => value,
  };
}

/// Money coming in for the month, by source: salary, bank balances,
/// e-wallets… Each counts in the calendar month of its date.
class IncomeViewModel extends PersistedListViewModel<IncomeModel> {
  IncomeViewModel(super.repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const defaultSource = 'Lain-lain';

  final DateTime Function() _clock;

  YearMonth get currentMonth => YearMonth.of(_clock());

  /// This month's sources, newest first.
  List<IncomeModel> get incomes => incomesIn(currentMonth);

  double get total => totalIn(currentMonth);

  List<IncomeModel> incomesIn(YearMonth month) =>
      items.where((i) => month.contains(i.date)).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  double totalIn(YearMonth month) =>
      incomesIn(month).fold(0, (sum, i) => sum + i.amount);

  Set<YearMonth> get monthsWithData => {
    for (final income in items) YearMonth.of(income.date),
  };

  /// The month of the first recorded income, where balance tracking starts.
  YearMonth? get firstMonth {
    final months = monthsWithData;
    return months.isEmpty
        ? null
        : months.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// This month's source with the same name (case-insensitive), if any.
  IncomeModel? sourceNamed(String source) {
    final name = resolveSource(source).toLowerCase();
    return incomes.where((i) => i.source.toLowerCase() == name).firstOrNull;
  }

  /// The source an income is saved with: blank means [defaultSource].
  static String resolveSource(String source) {
    final name = source.trim();
    return name.isEmpty ? defaultSource : name;
  }

  Future<void> add({required String source, required double amount}) {
    return upsert(
      IncomeModel(
        id: IdGenerator.next(),
        source: resolveSource(source),
        amount: amount,
        date: _clock(),
      ),
    );
  }

  /// Renames a source and tops up or replaces its amount. It stays in the
  /// month it was first recorded.
  Future<void> adjust(
    String id, {
    required String source,
    required double value,
    required AmountChange change,
  }) => commit([
    for (final income in items)
      if (income.id == id)
        income.copyWith(
          source: resolveSource(source),
          amount: change.apply(income.amount, value),
        )
      else
        income,
  ]);
}
