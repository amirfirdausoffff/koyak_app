import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/debt_model.dart';
import '../../../viewmodels/debt_view_model.dart';
import '../../shared/category_style.dart';
import '../../shared/widgets/amount_field.dart';
import '../../shared/widgets/confirm_dialogs.dart';
import '../../shared/widgets/koyak_sheet.dart';
import '../../shared/widgets/koyak_snack.dart';

/// Past months keep a removed debt in their history, so say so.
Future<bool> confirmDebtDelete(BuildContext context, DebtModel debt) =>
    confirmDelete(
      context,
      title: 'Padam Hutang?',
      itemName: debt.title,
      message:
          '"${debt.title}" akan dibuang dari senarai. Rekod bulan-bulan '
          'lepas kekal dalam sejarah.',
      summary: ConfirmSummary(
        icon: Icons.receipt_long_outlined,
        title: debt.title,
        subtitle: debt.category.label,
        amount: debt.amount,
      ),
    );

/// Add a new debt, or edit [debt] when given.
Future<void> showDebtFormSheet(BuildContext context, {DebtModel? debt}) =>
    showKoyakSheet<void>(
      context,
      title: debt == null ? 'Tambah Hutang' : 'Kemaskini Hutang',
      builder: (_) => DebtFormSheet(debt: debt),
    );

class DebtFormSheet extends StatefulWidget {
  const DebtFormSheet({super.key, this.debt});

  final DebtModel? debt;

  @override
  State<DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends State<DebtFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.debt?.title);
  late final _amount = TextEditingController(
    text: widget.debt?.amount.toStringAsFixed(2),
  );
  late DebtCategory _category = widget.debt?.category ?? DebtCategory.halal;
  late DateTime? _dueDate = widget.debt?.dueDate;

  bool get _isEditing => widget.debt != null;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      helpText: 'Tarikh akhir bayar',
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = CurrencyFormatter.parse(_amount.text)!;
    final dueDate = _dueDate;
    final confirmed = await confirmSave(
      context,
      title: _isEditing ? 'Kemaskini Hutang?' : 'Simpan Hutang?',
      summary: ConfirmSummary(
        icon: Icons.receipt_long_outlined,
        title: _title.text.trim(),
        subtitle: dueDate == null
            ? _category.label
            : '${_category.label} · sebelum ${dueDate.day}hb',
        amount: amount,
      ),
    );
    if (!confirmed || !mounted) return;

    final vm = context.read<DebtViewModel>();
    final existing = widget.debt;
    if (existing == null) {
      vm.add(
        title: _title.text,
        amount: amount,
        category: _category,
        dueDate: _dueDate,
      );
    } else {
      vm.upsert(
        existing.copyWith(
          title: _title.text.trim(),
          amount: amount,
          category: _category,
          dueDate: _dueDate,
          clearDueDate: _dueDate == null,
        ),
      );
    }
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final debt = widget.debt!;
    if (!await confirmDebtDelete(context, debt) || !mounted) return;

    final vm = context.read<DebtViewModel>()..remove(debt.id);
    Navigator.of(context).pop();
    showKoyakSnack(
      context,
      '"${debt.title}" dipadam',
      onUndo: () => vm.upsert(debt),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _title,
            autofocus: !_isEditing,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Nama hutang (cth: PTPTN, Kereta)',
            ),
            validator: (value) => (value?.trim().isEmpty ?? true)
                ? 'Nama hutang diperlukan'
                : null,
          ),
          const SizedBox(height: 10),
          AmountField(controller: _amount, hintText: 'Bayaran bulan ni'),
          const SizedBox(height: 16),
          SegmentedButton<DebtCategory>(
            segments: [
              for (final category in DebtCategory.values)
                ButtonSegment(value: category, label: Text(category.label)),
            ],
            selected: {_category},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                setState(() => _category = selection.first),
            style: SegmentedButton.styleFrom(
              selectedForegroundColor: _category.color,
              selectedBackgroundColor: _category.color.withValues(alpha: 0.14),
            ),
          ),
          const SizedBox(height: 12),
          _DueDateField(
            date: _dueDate,
            onPick: _pickDueDate,
            onClear: () => setState(() => _dueDate = null),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Simpan')),
          if (_isEditing) ...[
            const SizedBox(height: 4),
            TextButton(
              onPressed: _delete,
              style: TextButton.styleFrom(foregroundColor: AppColors.amber),
              child: const Text('Padam Hutang'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DueDateField extends StatelessWidget {
  const _DueDateField({
    required this.date,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? date;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final date = this.date;
    final radius = BorderRadius.circular(AppTheme.fieldRadius);
    return Material(
      color: AppColors.surfaceRaised,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onPick,
        child: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: SizedBox(
            height: 50,
            child: Row(
              children: [
                const Icon(
                  Icons.event_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    date == null
                        ? 'Tarikh akhir bayar (pilihan)'
                        : 'Setiap bulan, sebelum ${date.day}hb',
                    style: TextStyle(
                      color: date == null
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (date != null)
                  IconButton(
                    onPressed: onClear,
                    tooltip: 'Buang tarikh',
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
