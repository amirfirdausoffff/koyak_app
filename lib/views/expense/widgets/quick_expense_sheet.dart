import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../viewmodels/expense_view_model.dart';
import '../../shared/widgets/koyak_sheet.dart';
import '../../shared/widgets/koyak_snack.dart';
import 'quick_expense_form.dart';

/// Opens the quick form with the keyboard already up on the amount.
Future<void> showQuickExpenseSheet(BuildContext context) {
  final vm = context.read<ExpenseViewModel>();
  return showKoyakSheet<void>(
    context,
    title: 'Catat Belanja',
    builder: (sheetContext) => QuickExpenseForm(
      autofocus: true,
      showHeader: false,
      onSaved: (expense) {
        Navigator.of(sheetContext).pop();
        showKoyakSnack(
          context,
          '${expense.amount.asRinggit} · ${expense.title} dicatat',
          onUndo: () => vm.remove(expense.id),
        );
      },
    ),
  );
}
