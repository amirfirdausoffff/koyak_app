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

/// Everything recorded in one month, for the history detail screen.
@immutable
class MonthReport {
  const MonthReport({
    required this.month,
    required this.summary,
    required this.incomes,
    required this.debts,
    required this.timeline,
    required this.categoryShares,
  });

  final YearMonth month;
  final CashflowSummary summary;
  final List<IncomeModel> incomes;
  final List<DebtMonthStatus> debts;
  final List<ExpenseDayGroup> timeline;
  final List<CategoryShare> categoryShares;

  int get paidDebtCount => debts.where((d) => d.isPaid).length;

  int get expenseCount =>
      timeline.fold(0, (sum, day) => sum + day.expenses.length);
}
