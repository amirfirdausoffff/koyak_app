import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/debt_model.dart';
import '../../models/expense_model.dart';

// Visual styling lives in the view layer so models stay framework-free.

extension ExpenseCategoryStyle on ExpenseCategory {
  IconData get icon => switch (this) {
    ExpenseCategory.makan => Icons.restaurant_rounded,
    ExpenseCategory.minyak => Icons.local_gas_station_rounded,
    ExpenseCategory.bil => Icons.receipt_rounded,
    ExpenseCategory.barangDapur => Icons.shopping_basket_rounded,
    ExpenseCategory.beliBelah => Icons.shopping_bag_rounded,
    ExpenseCategory.lainLain => Icons.more_horiz_rounded,
  };
}

extension DebtCategoryStyle on DebtCategory {
  Color get color => switch (this) {
    DebtCategory.halal => AppColors.green,
    DebtCategory.risky => AppColors.amber,
  };
}
