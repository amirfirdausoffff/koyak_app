import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/income_model.dart';
import '../../viewmodels/income_view_model.dart';
import '../shared/category_style.dart';
import '../shared/widgets/amount_field.dart';
import '../shared/widgets/confirm_dialogs.dart';
import '../shared/widgets/koyak_sheet.dart';

Future<void> showIncomeEditSheet(BuildContext context, IncomeModel income) =>
    showKoyakSheet<void>(
      context,
      title: 'Kemaskini Sumber',
      builder: (_) => IncomeEditSheet(income: income),
    );

/// Top up, correct, rename or remove one money source.
class IncomeEditSheet extends StatefulWidget {
  const IncomeEditSheet({super.key, required this.income});

  final IncomeModel income;

  @override
  State<IncomeEditSheet> createState() => _IncomeEditSheetState();
}

class _IncomeEditSheetState extends State<IncomeEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.income.source);
  final _amount = TextEditingController();
  AmountChange _change = AmountChange.add;

  IncomeModel get _income => widget.income;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  /// The amount after this edit, or null while the input is invalid.
  double? _resultingAmount(String input) {
    if (input.trim().isEmpty) return _income.amount;
    final value = CurrencyFormatter.parse(input);
    return value == null ? null : _change.apply(_income.amount, value);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final value = CurrencyFormatter.parse(_amount.text) ?? 0;
    final change = _amount.text.trim().isEmpty ? AmountChange.add : _change;
    final name = IncomeViewModel.resolveSource(_name.text);
    final newAmount = change.apply(_income.amount, value);

    final nothingChanged =
        name == _income.source && newAmount == _income.amount;
    if (nothingChanged) {
      Navigator.of(context).pop();
      return;
    }

    final confirmed = await confirmSave(
      context,
      title: 'Kemaskini $name?',
      summary: ConfirmSummary(
        icon: moneySourceIcon(name),
        title: name,
        subtitle: switch (change) {
          AmountChange.add =>
            '${_income.amount.asRinggit} + ${value.asRinggit}',
          AmountChange.replace => 'Dulu ${_income.amount.asRinggit}',
        },
        amount: newAmount,
      ),
    );
    if (!confirmed || !mounted) return;

    await context.read<IncomeViewModel>().adjust(
      _income.id,
      source: name,
      value: value,
      change: change,
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await confirmDelete(
      context,
      title: 'Padam Sumber Duit?',
      itemName: _income.source,
      summary: ConfirmSummary(
        icon: moneySourceIcon(_income.source),
        title: _income.source,
        subtitle: 'Sejak ${DateFormatter.full(_income.date)}',
        amount: _income.amount,
      ),
    );
    if (!confirmed || !mounted) return;
    await context.read<IncomeViewModel>().remove(_income.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CurrentAmount(income: _income),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'Nama sumber'),
            validator: (value) => (value?.trim().isEmpty ?? true)
                ? 'Nama sumber diperlukan'
                : null,
          ),
          const SizedBox(height: 12),
          SegmentedButton<AmountChange>(
            segments: const [
              ButtonSegment(
                value: AmountChange.add,
                icon: Icon(Icons.add_rounded, size: 18),
                label: Text('Tambah'),
              ),
              ButtonSegment(
                value: AmountChange.replace,
                icon: Icon(Icons.edit_outlined, size: 18),
                label: Text('Tukar jumlah'),
              ),
            ],
            selected: {_change},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                setState(() => _change = selection.first),
          ),
          const SizedBox(height: 10),
          AmountField(
            controller: _amount,
            optional: true,
            allowZero: _change == AmountChange.replace,
            hintText: _change == AmountChange.add
                ? 'Jumlah nak ditambah'
                : 'Jumlah baru',
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder(
            valueListenable: _amount,
            builder: (context, value, _) {
              final result = _resultingAmount(value.text);
              return Text(
                result == null
                    ? ' '
                    : 'Jumlah lepas simpan: ${result.asRinggit}',
                style: const TextStyle(color: AppColors.textMuted),
              );
            },
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _save, child: const Text('Simpan')),
          const SizedBox(height: 4),
          TextButton(
            onPressed: _delete,
            style: TextButton.styleFrom(foregroundColor: AppColors.amber),
            child: const Text('Padam sumber ni'),
          ),
        ],
      ),
    );
  }
}

class _CurrentAmount extends StatelessWidget {
  const _CurrentAmount({required this.income});

  final IncomeModel income;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                moneySourceIcon(income.source),
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jumlah sekarang',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  Text(
                    income.amount.asRinggit,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
