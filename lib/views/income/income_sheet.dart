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
import 'income_edit_sheet.dart';

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
  final _amountFocus = FocusNode();

  @override
  void dispose() {
    _source.dispose();
    _amount.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  /// A suggestion that already exists opens it for a top-up instead.
  void _pickSuggestion(String name) {
    final existing = context.read<IncomeViewModel>().sourceNamed(name);
    if (existing != null) {
      showIncomeEditSheet(context, existing);
      return;
    }
    _source.text = name;
    _amountFocus.requestFocus();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final vm = context.read<IncomeViewModel>();
    final amount = CurrencyFormatter.parse(_amount.text)!;
    final existing = vm.sourceNamed(_source.text);

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
              subtitle: '${existing.amount.asRinggit} + ${amount.asRinggit}',
              amount: existing.amount + amount,
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
              onTap: () => showIncomeEditSheet(context, income),
            ),
          ],
        const SizedBox(height: 24),
        const Text(
          'Tambah sumber duit',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final name in IncomeSheet.suggestions)
              ActionChip(
                avatar: Icon(
                  moneySourceIcon(name),
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                label: Text(name),
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                onPressed: () => _pickSuggestion(name),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _source,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Nama sumber (cth: Gaji, Maybank, TNG)',
                ),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Nama sumber diperlukan'
                    : null,
              ),
              const SizedBox(height: 10),
              AmountField(
                controller: _amount,
                focusNode: _amountFocus,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tambah'),
              ),
            ],
          ),
        ),
      ],
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
