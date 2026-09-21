import 'package:flutter/foundation.dart';

import 'expense_model.dart';

/// One day in the expense timeline.
@immutable
class ExpenseDayGroup {
  const ExpenseDayGroup({required this.day, required this.expenses});

  final DateTime day;
  final List<ExpenseModel> expenses;

  double get total => expenses.fold(0, (sum, e) => sum + e.amount);
}
