import '../core/utils/id_generator.dart';
import '../models/debt_model.dart';
import '../models/year_month.dart';
import 'persisted_list_view_model.dart';

/// Debts counted in the monthly baki, plus one-off debts still owed from
/// earlier months. The getters without a month argument describe the
/// current month, which starts unpaid automatically.
class DebtViewModel extends PersistedListViewModel<DebtModel> {
  DebtViewModel(super.repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  YearMonth get currentMonth => YearMonth.of(_clock());

  /// This month's debts: unpaid first, then nearest due date, then title.
  List<DebtModel> get debts => debtsIn(currentMonth);

  /// One-off debts from earlier months, still owed when this month began.
  /// They are not part of this month's totals.
  List<DebtModel> get overdue => overdueIn(currentMonth);

  int get count => debts.length;

  int get paidCount => debts.where(isPaid).length;

  double get totalAmount => totalIn(currentMonth);

  double get paidAmount =>
      debts.where(isPaid).fold(0, (sum, d) => sum + d.amountIn(currentMonth));

  double get unpaidAmount => totalAmount - paidAmount;

  /// 0–1 share of this month's commitments already paid.
  double get progress => totalAmount == 0 ? 0 : paidAmount / totalAmount;

  bool isPaid(DebtModel debt) => debt.isPaidIn(currentMonth);

  double totalFor(DebtCategory category) => debts
      .where((d) => d.category == category)
      .fold(0, (sum, d) => sum + d.amountIn(currentMonth));

  /// Debts counted in [month]'s baki.
  List<DebtModel> debtsIn(YearMonth month) =>
      items.where((d) => d.isActiveIn(month)).toList()
        ..sort((a, b) => _byPriority(a, b, month));

  List<DebtModel> overdueIn(YearMonth month) =>
      items.where((d) => d.isOverdueIn(month)).toList()
        ..sort((a, b) => _byPriority(a, b, month));

  double totalIn(YearMonth month) =>
      debtsIn(month).fold(0, (sum, d) => sum + d.amountIn(month));

  Set<YearMonth> get monthsWithData => {
    for (final debt in items)
      for (final key in debt.payments.keys) ?YearMonth.tryParse(key),
  };

  Future<void> add({
    required String title,
    required double amount,
    required DebtCategory category,
    DebtKind kind = DebtKind.monthly,
    DateTime? dueDate,
    YearMonth? lastMonth,
  }) => upsert(
    DebtModel(
      id: IdGenerator.next(),
      title: title.trim(),
      amount: amount,
      category: category,
      createdAt: _clock(),
      kind: kind,
      dueDate: dueDate,
      lastMonth: kind == DebtKind.monthly ? lastMonth : null,
    ),
  );

  Future<void> togglePaid(String id) => commit([
    for (final debt in items)
      debt.id == id ? debt.togglePaidIn(currentMonth) : debt,
  ]);

  /// A debt added this month is deleted outright; an older one is ended so
  /// past months keep showing it in the history.
  @override
  Future<void> remove(String id) {
    final now = _clock();
    return commit([
      for (final debt in items)
        if (debt.id != id)
          debt
        else if (YearMonth.of(debt.createdAt).isBefore(YearMonth.of(now)))
          debt.endedOn(now),
    ]);
  }

  static int _byPriority(DebtModel a, DebtModel b, YearMonth month) {
    final aPaid = a.isPaidIn(month);
    if (aPaid != b.isPaidIn(month)) return aPaid ? 1 : -1;

    final aDue = a.dueDateIn(month);
    final bDue = b.dueDateIn(month);
    if (aDue != null && bDue != null) {
      final byDate = aDue.compareTo(bDue);
      if (byDate != 0) return byDate;
    } else if (aDue != null || bDue != null) {
      return aDue != null ? -1 : 1;
    }
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }
}
