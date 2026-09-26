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
  const QuickExpenseForm({
    super.key,
    this.autofocus = false,
    this.showHeader = true,
    this.onSaved,
  });

  final bool autofocus;
  final bool showHeader;
  final ValueChanged<ExpenseModel>? onSaved;

  @override
  State<QuickExpenseForm> createState() => _QuickExpenseFormState();
}

class _QuickExpenseFormState extends State<QuickExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _title = TextEditingController();
  final _category = TextEditingController(text: ExpenseCategory.makan.label);
  String? _account;
  bool _showAccountError = false;

  @override
  void initState() {
    super.initState();
    _amount.addListener(_refreshAmountLabel);
  }

  void _refreshAmountLabel() => setState(() {});

  @override
  void dispose() {
    _amount
      ..removeListener(_refreshAmountLabel)
      ..dispose();
    _title.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_account == null) {
      setState(() => _showAccountError = true);
      return;
    }

    final amount = CurrencyFormatter.parse(_amount.text)!;
    final category = ExpenseCategory.fromLabel(_category.text);
    final confirmed = await confirmSave(
      context,
      title: 'Simpan Belanja?',
      summary: ConfirmSummary(
        icon: category.icon,
        title: ExpenseViewModel.resolveTitle(_title.text, category),
        subtitle: '${category.label} · Guna $_account',
        amount: amount,
      ),
    );
    if (!confirmed || !mounted) return;

    final expense = await context.read<ExpenseViewModel>().add(
      amount: amount,
      category: category,
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
    final amount = CurrencyFormatter.parse(_amount.text);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showHeader) ...[
            const _QuickEntryHeader(),
            const SizedBox(height: 18),
          ],
          AmountField(
            controller: _amount,
            autofocus: widget.autofocus,
            composer: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => FocusScope.of(context).nextFocus(),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CategoryField(
                  controller: _category,
                  suggestions: expenses.categorySuggestions,
                  compact: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _AccountPickerField(
                  account: selected,
                  balance: selected == null
                      ? null
                      : selected.amount -
                            expenses.totalFromAccount(selected.source),
                  enabled: accounts.isNotEmpty,
                  showError: _showAccountError,
                  compact: true,
                  onTap: () => _pickAccount(accounts, expenses),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _save(),
            decoration: const InputDecoration(
              hintText: 'Contoh: Nasi lemak',
              prefixIcon: Icon(Icons.receipt_long_outlined),
            ),
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
            key: const ValueKey('save-expense'),
            onPressed: accounts.isEmpty ? null : _save,
            icon: const Icon(Icons.check_rounded),
            label: Text(
              amount == null
                  ? 'Simpan belanja'
                  : 'Simpan & tolak ${amount.asRinggit}',
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickEntryHeader extends StatelessWidget {
  const _QuickEntryHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.add_circle_outline_rounded, size: 30),
        SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Catat Belanja',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        Text(
          'Hari ini',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

class _CategoryField extends StatefulWidget {
  const _CategoryField({
    required this.controller,
    required this.suggestions,
    this.compact = false,
  });

  final TextEditingController controller;
  final List<ExpenseCategory> suggestions;
  final bool compact;

  @override
  State<_CategoryField> createState() => _CategoryFieldState();
}

class _CategoryFieldState extends State<_CategoryField> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<ExpenseCategory>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      displayStringForOption: (category) => category.label,
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        return widget.suggestions
            .where((category) => category.label.toLowerCase().contains(query))
            .take(6);
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
          widget.compact
              ? SizedBox(
                  height: 72,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Stack(
                      children: [
                        const Positioned(
                          left: 12,
                          top: 0,
                          bottom: 0,
                          child: Icon(
                            Icons.sell_outlined,
                            color: AppColors.textSecondary,
                            size: 22,
                          ),
                        ),
                        Positioned(
                          left: 42,
                          right: 8,
                          top: 0,
                          bottom: 0,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kategori',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 3),
                              SizedBox(
                                height: 18,
                                child: TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  textCapitalization:
                                      TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) => onSubmitted(),
                                  validator: (value) =>
                                      (value?.trim().isEmpty ?? true)
                                      ? 'Masukkan kategori'
                                      : null,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Pilih kategori',
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => onSubmitted(),
                  validator: (value) =>
                      (value?.trim().isEmpty ?? true)
                      ? 'Masukkan kategori'
                      : null,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    hintText: 'Pilih atau taip baru',
                    prefixIcon: Icon(Icons.sell_outlined),
                  ),
                ),
      optionsViewBuilder: (context, onSelected, options) {
        final categories = options.toList();
        if (categories.isEmpty) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: MediaQuery.sizeOf(context).width - 40,
              constraints: const BoxConstraints(maxHeight: 252),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: categories.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.border),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      category.icon,
                      color: AppColors.textSecondary,
                    ),
                    title: Text(category.label),
                    trailing: category.isCustom
                        ? const Text(
                            'Terkini',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          )
                        : null,
                    onTap: () => onSelected(category),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AccountPickerField extends StatelessWidget {
  const _AccountPickerField({
    required this.account,
    required this.balance,
    required this.enabled,
    required this.showError,
    this.compact = false,
    required this.onTap,
  });

  final IncomeModel? account;
  final double? balance;
  final bool enabled;
  final bool showError;
  final bool compact;
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
    if (compact) {
      return _CompactAccountPicker(
        account: account,
        balance: balance,
        enabled: enabled,
        showError: showError,
        onTap: onTap,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: selected
              ? AppColors.green.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: radius,
          child: InkWell(
            key: const ValueKey('expense-account-picker'),
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

class _CompactAccountPicker extends StatelessWidget {
  const _CompactAccountPicker({
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: selected
              ? AppColors.green.withValues(alpha: 0.08)
              : AppColors.surfaceRaised,
          borderRadius: radius,
          child: InkWell(
            key: const ValueKey('expense-account-picker'),
            onTap: enabled ? onTap : null,
            borderRadius: radius,
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? moneySourceIcon(account!.source)
                        : Icons.account_balance_wallet_outlined,
                    color: selected ? AppColors.green : AppColors.textSecondary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Guna akaun',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          selected
                              ? '${account!.source} · ${balance!.asRinggit}'
                              : 'Pilih akaun',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: enabled
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showError) ...[
          const SizedBox(height: 5),
          Text(
            'Pilih akaun',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}
