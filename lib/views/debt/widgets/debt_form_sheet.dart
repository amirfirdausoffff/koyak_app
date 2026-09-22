import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/debt_model.dart';
import '../../../models/year_month.dart';
import '../../../viewmodels/debt_view_model.dart';
import '../../shared/category_style.dart';
import '../../shared/widgets/amount_field.dart';
import '../../shared/widgets/confirm_dialogs.dart';
import '../../shared/widgets/koyak_sheet.dart';
import '../../shared/widgets/koyak_snack.dart';
import '../../shared/widgets/month_picker_dialog.dart';

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
  late DebtKind _kind = widget.debt?.kind ?? DebtKind.monthly;
  late DateTime? _dueDate = widget.debt?.dueDate;
  late YearMonth? _lastMonth = widget.debt?.lastMonth;

  late final YearMonth _currentMonth;

  bool get _isEditing => widget.debt != null;

  bool get _isOnce => _kind == DebtKind.once;

  /// Switching kind would rewrite past months, so only a debt started this
  /// month may change it.
  bool get _canChangeKind =>
      widget.debt == null || widget.debt!.startMonth == _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = context.read<DebtViewModel>().currentMonth;
  }

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

  Future<void> _pickLastMonth() async {
    final picked = await showMonthPicker(
      context,
      title: 'Bulan Terakhir Bayar',
      first: _currentMonth,
      initial: _lastMonth,
    );
    if (picked != null) setState(() => _lastMonth = picked);
  }

  String? get _dueDateText {
    final due = _dueDate;
    if (due == null) return null;
    return _isOnce
        ? 'Sebelum ${DateFormatter.full(due)}'
        : 'Setiap bulan, sebelum ${due.day}hb';
  }

  String? get _lastMonthText {
    final last = _lastMonth;
    if (last == null) return null;
    final months = last.compareTo(_currentMonth) + 1;
    return 'Hingga ${DateFormatter.monthYearShort(last.start)} '
        '($months bulan lagi)';
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = CurrencyFormatter.parse(_amount.text)!;
    final dueDate = _dueDate;
    final lastMonth = _isOnce ? null : _lastMonth;
    final confirmed = await confirmSave(
      context,
      title: _isEditing ? 'Kemaskini Hutang?' : 'Simpan Hutang?',
      summary: ConfirmSummary(
        icon: Icons.receipt_long_outlined,
        title: _title.text.trim(),
        subtitle: [
          _isOnce ? 'Sekali bayar' : 'Bulanan',
          if (dueDate != null)
            _isOnce
                ? 'sebelum ${DateFormatter.short(dueDate)}'
                : 'sebelum ${dueDate.day}hb',
          if (lastMonth != null)
            'hingga ${DateFormatter.monthYearShort(lastMonth.start)}',
          _category.label,
        ].join(' · '),
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
        kind: _kind,
        dueDate: dueDate,
        lastMonth: lastMonth,
      );
    } else {
      vm.upsert(
        existing.copyWith(
          title: _title.text.trim(),
          amount: amount,
          category: _category,
          kind: _kind,
          dueDate: dueDate,
          clearDueDate: dueDate == null,
          lastMonth: lastMonth,
          clearLastMonth: lastMonth == null,
        ),
      );
    }
    Navigator.of(context).pop();
  }

  String get _kindHint {
    if (!_canChangeKind) {
      return 'Hutang dari bulan lepas tak boleh tukar jenis.';
    }
    return _isOnce
        ? 'Dikira bulan ni je. Kalau belum bayar, dia ikut ke bulan depan '
              'sebagai tertunggak.'
        : 'Ulang setiap bulan sampai bulan terakhir, atau sampai kau padam.';
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
          const SizedBox(height: 12),
          SegmentedButton<DebtKind>(
            segments: [
              for (final kind in DebtKind.values)
                ButtonSegment(
                  value: kind,
                  label: Text(kind.label),
                  icon: Icon(
                    kind == DebtKind.monthly
                        ? Icons.event_repeat_rounded
                        : Icons.looks_one_outlined,
                    size: 18,
                  ),
                ),
            ],
            selected: {_kind},
            showSelectedIcon: false,
            onSelectionChanged: _canChangeKind
                ? (selection) => setState(() => _kind = selection.first)
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            _kindHint,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          AmountField(
            controller: _amount,
            hintText: _isOnce ? 'Jumlah hutang' : 'Bayaran sebulan',
          ),
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
          _PickerField(
            icon: Icons.event_outlined,
            placeholder: 'Tarikh akhir bayar (pilihan)',
            value: _dueDateText,
            onPick: _pickDueDate,
            onClear: () => setState(() => _dueDate = null),
            clearTooltip: 'Buang tarikh',
          ),
          if (!_isOnce) ...[
            const SizedBox(height: 10),
            _PickerField(
              icon: Icons.flag_outlined,
              placeholder: 'Bulan terakhir bayar (pilihan)',
              value: _lastMonthText,
              onPick: _pickLastMonth,
              onClear: () => setState(() => _lastMonth = null),
              clearTooltip: 'Tiada tarikh tamat',
            ),
          ],
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

/// Tappable field that opens a picker; [value] null shows [placeholder].
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.placeholder,
    required this.value,
    required this.onPick,
    required this.onClear,
    required this.clearTooltip,
  });

  final IconData icon;
  final String placeholder;
  final String? value;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final String clearTooltip;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
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
                Icon(icon, size: 20, color: AppColors.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value ?? placeholder,
                    style: TextStyle(
                      color: value == null
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (value != null)
                  IconButton(
                    onPressed: onClear,
                    tooltip: clearTooltip,
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
