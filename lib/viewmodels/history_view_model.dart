import 'package:flutter/foundation.dart';

import '../models/cashflow_summary.dart';
import '../models/month_report.dart';
import '../models/year_month.dart';
import 'cashflow_ledger.dart';
import 'debt_view_model.dart';
import 'expense_view_model.dart';
import 'income_view_model.dart';

/// Past months, read from the same records the current month uses.
class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel({
    required this._incomes,
    required this._debts,
    required this._expenses,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       _ledger = CashflowLedger(
         incomes: _incomes,
         debts: _debts,
         expenses: _expenses,
       ) {
    for (final source in _sources) {
      source.addListener(notifyListeners);
    }
  }

  final IncomeViewModel _incomes;
  final DebtViewModel _debts;
  final ExpenseViewModel _expenses;
  final DateTime Function() _clock;
  final CashflowLedger _ledger;

  List<ChangeNotifier> get _sources => [_incomes, _debts, _expenses];

  /// Finished months that have any income, expense or debt payment,
  /// newest first.
  List<MonthOverview> get pastMonths {
    final current = YearMonth.of(_clock());
    final months =
        {
            ..._incomes.monthsWithData,
            ..._expenses.monthsWithData,
            ..._debts.monthsWithData,
          }.where((m) => m.isBefore(current)).toList()
          ..sort((a, b) => b.compareTo(a));

    return [
      for (final month in months)
        MonthOverview(month: month, summary: summaryFor(month)),
    ];
  }

  /// Includes the baki carried in from the month before.
  CashflowSummary summaryFor(YearMonth month) => _ledger.summaryFor(month);

  MonthReport reportFor(YearMonth month) {
    final debts = _debts.monthOf(month);
    return MonthReport(
      month: month,
      summary: summaryFor(month),
      incomes: _incomes.incomesIn(month),
      debts: debts.debts,
      overdue: debts.overdue,
      timeline: _expenses.timelineFor(month),
      categoryShares: _expenses.categoryBreakdownFor(month),
    );
  }

  @override
  void dispose() {
    for (final source in _sources) {
      source.removeListener(notifyListeners);
    }
    super.dispose();
  }
}
