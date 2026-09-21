import 'package:flutter/foundation.dart';

import 'expense_model.dart';

/// How much of total spending went to one [category].
@immutable
class CategoryShare {
  const CategoryShare({
    required this.category,
    required this.amount,
    required this.percentage,
  });

  final ExpenseCategory category;
  final double amount;

  /// 0–100.
  final double percentage;
}
