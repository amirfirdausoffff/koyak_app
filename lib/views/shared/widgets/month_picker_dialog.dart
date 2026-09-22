import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/year_month.dart';
import 'koyak_dialog.dart';

/// Picks a calendar month no earlier than [first]; null when cancelled.
Future<YearMonth?> showMonthPicker(
  BuildContext context, {
  required String title,
  required YearMonth first,
  YearMonth? initial,
}) {
  final start = initial == null || initial.isBefore(first) ? first : initial;
  return showDialog<YearMonth>(
    context: context,
    builder: (_) =>
        _MonthPickerDialog(title: title, first: first, initial: start),
  );
}

class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({
    required this.title,
    required this.first,
    required this.initial,
  });

  final String title;
  final YearMonth first;
  final YearMonth initial;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  /// Long enough for a housing loan.
  static const _yearsAhead = 40;

  late YearMonth _selected = widget.initial;
  late int _year = widget.initial.year;

  int get _firstYear => widget.first.year;

  @override
  Widget build(BuildContext context) {
    return KoyakDialog(
      icon: Icons.event_available_outlined,
      title: widget.title,
      message: DateFormatter.month(_selected.start),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _year > _firstYear
                    ? () => setState(() => _year--)
                    : null,
                tooltip: 'Tahun sebelum',
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  '$_year',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: _year < _firstYear + _yearsAhead
                    ? () => setState(() => _year++)
                    : null,
                tooltip: 'Tahun depan',
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var row = 0; row < 3; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  for (var col = 0; col < 4; col++) ...[
                    if (col > 0) const SizedBox(width: 8),
                    Expanded(child: _cell(YearMonth(_year, row * 4 + col + 1))),
                  ],
                ],
              ),
            ),
        ],
      ),
      primaryLabel: 'Pilih',
      onPrimary: () => Navigator.of(context).pop(_selected),
    );
  }

  Widget _cell(YearMonth month) {
    final enabled = !month.isBefore(widget.first);
    final selected = month == _selected;
    final radius = BorderRadius.circular(10);
    return Material(
      color: selected
          ? AppColors.green.withValues(alpha: 0.16)
          : AppColors.surfaceRaised,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: enabled ? () => setState(() => _selected = month) : null,
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(
              DateFormatter.monthShort(month.start),
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.green
                    : enabled
                    ? AppColors.textPrimary
                    : AppColors.textMuted.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
