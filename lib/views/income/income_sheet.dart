import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/income_model.dart';
import '../../viewmodels/expense_view_model.dart';
import '../../viewmodels/income_view_model.dart';
import '../shared/category_style.dart';
import '../shared/widgets/amount_field.dart';
import '../shared/widgets/confirm_dialogs.dart';
import '../shared/widgets/koyak_sheet.dart';
import 'account_history_view.dart';

Future<void> showIncomeSheet(BuildContext context) => showKoyakSheet<void>(
  context,
  title: 'Duit Kau · ${DateFormatter.month(DateTime.now())}',
  builder: (_) => const IncomeSheet(),
);

/// Every place the month's money sits: salary, bank balances, e-wallets.
class IncomeSheet extends StatefulWidget {
  const IncomeSheet({super.key});

  static const suggestions = ['Gaji', 'Maybank', 'GX Bank', 'TNG', 'Tunai'];

  @override
  State<IncomeSheet> createState() => _IncomeSheetState();
}

class _IncomeSheetState extends State<IncomeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _source = TextEditingController();
  final _amount = TextEditingController();
  final _sourceFocus = FocusNode();
  final _amountFocus = FocusNode();
  bool _isAddExpanded = false;

  @override
  void dispose() {
    _source.dispose();
    _amount.dispose();
    _sourceFocus.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  /// Existing names become a top-up; new names create a source on save.
  void _pickSuggestion(String name) {
    setState(() => _isAddExpanded = true);
    _source.value = TextEditingValue(
      text: name,
      selection: TextSelection.collapsed(offset: name.length),
    );
    _amountFocus.requestFocus();
  }

  void _toggleAdd() {
    setState(() => _isAddExpanded = !_isAddExpanded);
    if (_isAddExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _sourceFocus.requestFocus();
      });
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final vm = context.read<IncomeViewModel>();
    final amount = CurrencyFormatter.parse(_amount.text)!;
    final existing = vm.sourceNamed(_source.text);
    final spent = existing == null
        ? 0.0
        : context.read<ExpenseViewModel>().totalFromAccount(existing.source);
    final currentBalance = existing == null ? 0.0 : existing.amount - spent;

    final confirmed = existing == null
        ? await confirmSave(
            context,
            title: 'Tambah Duit?',
            summary: ConfirmSummary(
              icon: moneySourceIcon(_source.text),
              title: IncomeViewModel.resolveSource(_source.text),
              subtitle: 'Dikira dalam ${DateFormatter.month(DateTime.now())}',
              amount: amount,
            ),
          )
        : await confirmSave(
            // Same name this month: top up instead of listing it twice.
            context,
            title: 'Tambah ke ${existing.source}?',
            summary: ConfirmSummary(
              icon: moneySourceIcon(existing.source),
              title: existing.source,
              subtitle: '${currentBalance.asRinggit} + ${amount.asRinggit}',
              amount: currentBalance + amount,
            ),
            confirmLabel: 'Tambah',
          );
    if (!confirmed || !mounted) return;

    if (existing == null) {
      await vm.add(source: _source.text, amount: amount);
    } else {
      await vm.adjust(
        existing.id,
        source: existing.source,
        value: amount,
        change: AmountChange.add,
      );
    }
    if (!mounted) return;
    _source.clear();
    _amount.clear();
    setState(() => _isAddExpanded = false);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<IncomeViewModel>();
    final expenses = context.watch<ExpenseViewModel>();
    final incomes = vm.incomes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TotalCard(
          total: vm.total - expenses.total,
          sourceCount: incomes.length,
        ),
        const SizedBox(height: 12),
        if (incomes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Belum ada duit direkod. Tambah gaji, baki bank atau e\u2011wallet '
              'kat bawah.',
              style: TextStyle(color: AppColors.textSecondary, height: 1.45),
            ),
          )
        else
          for (final (index, income) in incomes.indexed) ...[
            if (index > 0) const SizedBox(height: 8),
            _SourceTile(
              income: income,
              spent: expenses.totalFromAccount(income.source),
              onTap: () => AccountHistoryView.open(context, income),
            ),
          ],
        const SizedBox(height: 20),
        _AddMoneyComposer(
          expanded: _isAddExpanded,
          formKey: _formKey,
          sourceController: _source,
          amountController: _amount,
          sourceFocus: _sourceFocus,
          amountFocus: _amountFocus,
          suggestions: {
            ...incomes.map((income) => income.source),
            ...IncomeSheet.suggestions,
          }.toList(),
          recentSources: incomes
              .map((income) => income.source)
              .take(3)
              .toList(),
          onToggle: _toggleAdd,
          onSuggestion: _pickSuggestion,
          onSubmit: _submit,
        ),
      ],
    );
  }
}

class _AddMoneyComposer extends StatelessWidget {
  const _AddMoneyComposer({
    required this.expanded,
    required this.formKey,
    required this.sourceController,
    required this.amountController,
    required this.sourceFocus,
    required this.amountFocus,
    required this.suggestions,
    required this.recentSources,
    required this.onToggle,
    required this.onSuggestion,
    required this.onSubmit,
  });

  final bool expanded;
  final GlobalKey<FormState> formKey;
  final TextEditingController sourceController;
  final TextEditingController amountController;
  final FocusNode sourceFocus;
  final FocusNode amountFocus;
  final List<String> suggestions;
  final List<String> recentSources;
  final VoidCallback onToggle;
  final ValueChanged<String> onSuggestion;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: expanded
                ? AppColors.green.withValues(alpha: 0.42)
                : AppColors.border,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, expanded ? 16 : 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                key: const ValueKey('toggle-add-income'),
                borderRadius: BorderRadius.circular(14),
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          Icons.add_card_rounded,
                          size: 20,
                          color: expanded
                              ? AppColors.green
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tambah duit',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'Topup akaun atau cipta sumber baru',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (expanded) ...[
                const Divider(height: 12),
                if (recentSources.isNotEmpty) ...[
                  const Text(
                    'Akaun terkini',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final source in recentSources)
                        ActionChip(
                          avatar: Icon(
                            moneySourceIcon(source),
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          label: Text(source),
                          onPressed: () => onSuggestion(source),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RawAutocomplete<String>(
                        textEditingController: sourceController,
                        focusNode: sourceFocus,
                        displayStringForOption: (option) => option,
                        optionsBuilder: (value) {
                          final query = value.text.trim().toLowerCase();
                          if (query.isEmpty) return suggestions;
                          return suggestions.where(
                            (option) => option.toLowerCase().contains(query),
                          );
                        },
                        onSelected: onSuggestion,
                        fieldViewBuilder:
                            (context, controller, focusNode, onSubmitted) =>
                                TextFormField(
                                  key: const ValueKey('income-source-field'),
                                  controller: controller,
                                  focusNode: focusNode,
                                  textCapitalization: TextCapitalization.words,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) =>
                                      amountFocus.requestFocus(),
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.search_rounded),
                                    labelText:
                                        'Pilih akaun atau taip nama baru',
                                    hintText: 'Cth: GX Bank, Gaji, Tunai',
                                  ),
                                  validator: (value) =>
                                      (value?.trim().isEmpty ?? true)
                                      ? 'Nama sumber diperlukan'
                                      : null,
                                ),
                        optionsViewBuilder: (context, onSelected, options) {
                          final items = options.toList();
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              color: AppColors.surfaceRaised,
                              elevation: 8,
                              borderRadius: BorderRadius.circular(14),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 220,
                                  maxWidth: 320,
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    final item = items[index];
                                    return ListTile(
                                      dense: true,
                                      leading: Icon(
                                        moneySourceIcon(item),
                                        size: 20,
                                      ),
                                      title: Text(item),
                                      onTap: () => onSelected(item),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      AmountField(
                        controller: amountController,
                        focusNode: amountFocus,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => onSubmit(),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const ValueKey('save-income'),
                        onPressed: onSubmit,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Simpan'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total, required this.sourceCount});

  final double total;
  final int sourceCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jumlah baki bulan ni',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      total.asRinggit,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$sourceCount sumber',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.income,
    required this.spent,
    required this.onTap,
  });

  final IncomeModel income;
  final double spent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Material(
      color: AppColors.surfaceRaised,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  moneySourceIcon(income.source),
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      income.source,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      spent > 0
                          ? 'Belanja ${spent.asRinggit} · sejak ${DateFormatter.short(income.date)}'
                          : 'Sejak ${DateFormatter.short(income.date)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                (income.amount - spent).asRinggit,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
