import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/expense_model.dart';
import '../../../models/income_model.dart';
import '../../../viewmodels/expense_view_model.dart';
import '../../../viewmodels/income_view_model.dart';
import '../../shared/category_style.dart';
import '../../shared/widgets/amount_field.dart';
import '../../shared/widgets/confirm_dialogs.dart';
import 'expense_account_picker.dart';

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
  String? _account;
  bool _showAccountError = false;

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_account == null) {
      setState(() => _showAccountError = true);
      return;
    }

    final amount = CurrencyFormatter.parse(_amount.text)!;
    final confirmed = await confirmSave(
      context,
      title: 'Simpan Belanja?',
      summary: ConfirmSummary(
        icon: _category.icon,
        title: ExpenseViewModel.resolveTitle(_title.text, _category),
        subtitle: '${_category.label} · Guna $_account',
        amount: amount,
      ),
    );
    if (!confirmed || !mounted) return;

    final expense = await context.read<ExpenseViewModel>().add(
      amount: amount,
      category: _category,
      account: _account!,
      title: _title.text,
    );
    if (!mounted) return;

    HapticFeedback.lightImpact();
    _amount.clear();
    _title.clear();
    setState(() => _account = null);
    widget.onSaved?.call(expense);
  }

  Future<void> _pickAccount(
    List<IncomeModel> accounts,
    ExpenseViewModel expenses,
  ) async {
    final account = await showExpenseAccountPicker(
      context,
      accounts: accounts,
      expenses: expenses,
      selectedAccount: _account,
    );
    if (account == null || !mounted) return;
    setState(() {
      _account = account;
      _showAccountError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<IncomeViewModel>().incomes;
    final expenses = context.watch<ExpenseViewModel>();
    final accountNames = accounts.map((income) => income.source).toSet();
    if (!accountNames.contains(_account)) _account = null;
    final selected = _account == null
        ? null
        : accounts.firstWhere((account) => account.source == _account);

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
          _AccountPickerField(
            account: selected,
            balance: selected == null
                ? null
                : selected.amount - expenses.totalFromAccount(selected.source),
            enabled: accounts.isNotEmpty,
            showError: _showAccountError,
            onTap: () => _pickAccount(accounts, expenses),
          ),
          if (accounts.isEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Tambah akaun dulu melalui bahagian Duit (contoh: Maybank, TNG atau Tunai).',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: accounts.isEmpty ? null : _save,
            icon: const Icon(Icons.check_rounded),
            label: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _AccountPickerField extends StatelessWidget {
  const _AccountPickerField({
    required this.account,
    required this.balance,
    required this.enabled,
    required this.showError,
    required this.onTap,
  });

  final IncomeModel? account;
  final double? balance;
  final bool enabled;
  final bool showError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = account != null;
    final borderColor = showError
        ? Theme.of(context).colorScheme.error
        : selected
        ? AppColors.green.withValues(alpha: 0.65)
        : AppColors.border;
    final radius = BorderRadius.circular(16);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: selected
              ? AppColors.green.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: radius,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: radius,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      selected
                          ? moneySourceIcon(account!.source)
                          : Icons.account_balance_wallet_outlined,
                      color: selected
                          ? AppColors.green
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Belanja guna akaun mana?',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selected ? account!.source : 'Pilih akaun duit',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: enabled
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Baki',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          balance!.asRinggit,
                          style: const TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    )
                  else
                    const Icon(
                      Icons.unfold_more_rounded,
                      color: AppColors.textSecondary,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (showError) ...[
          const SizedBox(height: 6),
          Text(
            'Pilih akaun untuk belanja ini',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
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
