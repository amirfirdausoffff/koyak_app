import '../core/utils/id_generator.dart';
import '../models/income_model.dart';
import '../models/year_month.dart';
import 'persisted_list_view_model.dart';

/// Income counts in the calendar month of its date: add the salary when it
/// arrives and it belongs to that month.
class IncomeViewModel extends PersistedListViewModel<IncomeModel> {
  IncomeViewModel(super.repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const defaultSource = 'Gaji';

  final DateTime Function() _clock;

  YearMonth get currentMonth => YearMonth.of(_clock());

  /// This month's incomes, newest first.
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

  Future<void> add({required String source, required double amount}) {
    final name = source.trim();
    return upsert(
      IncomeModel(
        id: IdGenerator.next(),
        source: name.isEmpty ? defaultSource : name,
        amount: amount,
        date: _clock(),
      ),
    );
  }
}
