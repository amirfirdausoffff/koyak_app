import '../models/cashflow_summary.dart';
import '../models/year_month.dart';
import 'debt_view_model.dart';
import 'expense_view_model.dart';
import 'income_view_model.dart';

/// Month-by-month balance: whatever is left at the end of a month carries
/// into the next one, so a salary paid on the 25th keeps working in the
/// following month.
///
/// Tracking starts at the month of the first recorded income; debts and
/// expenses before that don't carry, so a mid-month install doesn't open
/// next month in the red.
class CashflowLedger {
  const CashflowLedger({
    required this.incomes,
    required this.debts,
    required this.expenses,
  });

  final IncomeViewModel incomes;
  final DebtViewModel debts;
  final ExpenseViewModel expenses;

  /// Baki at the end of the month before [month].
  double carriedInto(YearMonth month) {
    final start = incomes.firstMonth;
    if (start == null) return 0;

    var balance = 0.0;
    for (var m = start; m.isBefore(month); m = m.next) {
      balance += incomes.totalIn(m) - debts.totalIn(m) - expenses.totalIn(m);
    }
    return balance;
  }

  /// [daysRemaining] is only non-zero for the running month.
  CashflowSummary summaryFor(YearMonth month, {int daysRemaining = 0}) =>
      calculate(
        carriedForward: carriedInto(month),
        totalIncome: incomes.totalIn(month),
        totalDebt: debts.totalIn(month),
        totalExpense: expenses.totalIn(month),
        daysRemaining: daysRemaining,
      );

  /// Baki = Baki bulan lepas + Duit masuk − Hutang − Belanja.
  /// Had Harian = Baki ÷ [daysRemaining]; zero for a finished month.
  ///
  /// Hutang counts every commitment for the month, paid or not — that money
  /// is spoken for either way.
  static CashflowSummary calculate({
    required double totalIncome,
    required double totalDebt,
    required double totalExpense,
    double carriedForward = 0,
    int daysRemaining = 0,
  }) {
    final netRemaining =
        carriedForward + totalIncome - totalDebt - totalExpense;
    return CashflowSummary(
      totalIncome: totalIncome,
      totalDebt: totalDebt,
      totalExpense: totalExpense,
      carriedForward: carriedForward,
      netRemaining: netRemaining,
      dailyLimit: netRemaining > 0 && daysRemaining > 0
          ? netRemaining / daysRemaining
          : 0,
      daysRemaining: daysRemaining,
    );
  }
}
