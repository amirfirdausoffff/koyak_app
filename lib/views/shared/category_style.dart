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

/// Guesses an icon for a money source from its name.
IconData moneySourceIcon(String source) {
  final name = source.toLowerCase();
  bool mentions(List<String> words) => words.any(name.contains);

  if (mentions(['gaji', 'salary', 'elaun', 'bonus'])) {
    return Icons.work_outline_rounded;
  }
  if (mentions(['tng', 'touch', 'grab', 'boost', 'shopee', 'wallet', 'mae'])) {
    return Icons.account_balance_wallet_outlined;
  }
  if (mentions(['tunai', 'cash', 'duit poket'])) {
    return Icons.payments_outlined;
  }
  if (mentions([
    'bank',
    'maybank',
    'cimb',
    'rhb',
    'bsn',
    'bimb',
    'public',
    'hong leong',
    'ambank',
    'affin',
    'muamalat',
    'rakyat',
    'gx',
    'aeon',
    'ryt',
    'asb',
    'tabung',
    'simpanan',
  ])) {
    return Icons.account_balance_outlined;
  }
  return Icons.savings_outlined;
}
