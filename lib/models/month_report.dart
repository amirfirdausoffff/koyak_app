import 'package:flutter/foundation.dart';

import 'cashflow_summary.dart';
import 'category_share.dart';
import 'debt_model.dart';
import 'expense_day_group.dart';
import 'income_model.dart';
import 'year_month.dart';

/// One row of the monthly history list.
@immutable
class MonthOverview {
  const MonthOverview({required this.month, required this.summary});

  final YearMonth month;
  final CashflowSummary summary;
}

/// How a debt stood in a given month.
@immutable
class DebtMonthStatus {
  const DebtMonthStatus({
    required this.debt,
    required this.amount,
    required this.isPaid,
  });

  final DebtModel debt;
  final double amount;
  final bool isPaid;
}

/// Every debt listed in one month.
@immutable
class DebtMonth {
  const DebtMonth({
    required this.month,
    required this.debts,
    required this.overdue,
  });

  final YearMonth month;

  /// Counted in the month's baki.
  final List<DebtMonthStatus> debts;

  /// One-off debts from earlier months still owed; they counted in their
  /// own month.
  final List<DebtMonthStatus> overdue;

  double get total => debts.fold(0, (sum, d) => sum + d.amount);

  double get paidTotal =>
      debts.where((d) => d.isPaid).fold(0, (sum, d) => sum + d.amount);

  int get paidCount => debts.where((d) => d.isPaid).length;
}

/// Everything recorded in one month, for the history detail screen.
@immutable
class MonthReport {
  const MonthReport({
    required this.month,
    required this.summary,
    required this.incomes,
    required this.debts,
    this.overdue = const [],
    required this.timeline,
    required this.categoryShares,
  });

  final YearMonth month;
  final CashflowSummary summary;
  final List<IncomeModel> incomes;

  /// Debts counted in this month's baki.
  final List<DebtMonthStatus> debts;

  /// One-off debts from earlier months still owed this month; they counted
  /// in their own month.
  final List<DebtMonthStatus> overdue;

  final List<ExpenseDayGroup> timeline;
  final List<CategoryShare> categoryShares;

  int get paidDebtCount => debts.where((d) => d.isPaid).length;

  int get expenseCount =>
      timeline.fold(0, (sum, day) => sum + day.expenses.length);
}
