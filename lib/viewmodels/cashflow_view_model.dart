import 'package:flutter/foundation.dart';

import '../core/utils/date_helper.dart';
import '../models/cashflow_summary.dart';
import '../models/year_month.dart';
import 'cashflow_ledger.dart';
import 'debt_view_model.dart';
import 'expense_view_model.dart';
import 'income_view_model.dart';

/// Derives this month's live cashflow from income, debt and expense state.
/// A new calendar month starts by itself with last month's baki carried in;
/// nothing is deleted.
class CashflowViewModel extends ChangeNotifier {
  CashflowViewModel({
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
      source.addListener(_recalculate);
    }
    _recalculate();
  }

  final IncomeViewModel _incomes;
  final DebtViewModel _debts;
  final ExpenseViewModel _expenses;
  final DateTime Function() _clock;
  final CashflowLedger _ledger;

  CashflowSummary _summary = CashflowSummary.empty;
  bool _isReady = false;

  CashflowSummary get summary => _summary;

  /// True once every source has finished loading from storage.
  bool get isReady => _isReady;

  List<ChangeNotifier> get _sources => [_incomes, _debts, _expenses];

  /// Re-runs the maths, e.g. when the app resumes on a new day or month.
  void refresh() => _recalculate();

  void _recalculate() {
    final now = _clock();
    final next = _ledger.summaryFor(
      YearMonth.of(now),
      daysRemaining: DateHelper.daysRemainingInMonth(now),
    );
    final ready = _incomes.isLoaded && _debts.isLoaded && _expenses.isLoaded;
    if (next == _summary && ready == _isReady) return;

    _summary = next;
    _isReady = ready;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final source in _sources) {
      source.removeListener(_recalculate);
    }
    super.dispose();
  }
}
