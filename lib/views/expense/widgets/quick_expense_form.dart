import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/expense_model.dart';
import '../../../viewmodels/expense_view_model.dart';
import '../../shared/category_style.dart';
import '../../shared/widgets/amount_field.dart';
import '../../shared/widgets/confirm_dialogs.dart';

/// Under-3-seconds entry: type the amount, tap a category, hit enter.
/// The title is optional and defaults to the category name.
class QuickExpenseForm extends StatefulWidget {
  const QuickExpenseForm({super.key, this.autofocus = false, this.onSaved});

  final bool autofocus;
  final ValueChanged<ExpenseModel>? onSaved;

  @override
  State<QuickExpenseForm> createState() => _QuickExpenseFormState();
}

class _QuickExpenseFormState extends State<QuickExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _title = TextEditingController();
  ExpenseCategory _category = ExpenseCategory.makan;

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = CurrencyFormatter.parse(_amount.text)!;
    final confirmed = await confirmSave(
      context,
      title: 'Simpan Belanja?',
      summary: ConfirmSummary(
        icon: _category.icon,
        title: ExpenseViewModel.resolveTitle(_title.text, _category),
        subtitle: _category.label,
        amount: amount,
      ),
    );
    if (!confirmed || !mounted) return;

    final expense = await context.read<ExpenseViewModel>().add(
      amount: amount,
      category: _category,
      title: _title.text,
    );
    if (!mounted) return;

    HapticFeedback.lightImpact();
    _amount.clear();
    _title.clear();
    widget.onSaved?.call(expense);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AmountField(
            controller: _amount,
            autofocus: widget.autofocus,
            large: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _save(),
            decoration: const InputDecoration(
              hintText: 'Tajuk (pilihan) — cth: Nasi lemak',
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in ExpenseCategory.values)
                _CategoryChip(
                  category: category,
                  selected: category == _category,
                  onSelected: () => setState(() => _category = category),
                ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onSelected,
  });

  final ExpenseCategory category;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.green : AppColors.textSecondary;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onSelected(),
      avatar: Icon(category.icon, size: 16, color: color),
      label: Text(category.label),
      labelStyle: TextStyle(
        color: color,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      selectedColor: AppColors.green.withValues(alpha: 0.14),
      side: BorderSide(
        color: selected
            ? AppColors.green.withValues(alpha: 0.6)
            : Colors.transparent,
      ),
    );
  }
}
