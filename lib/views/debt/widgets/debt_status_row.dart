import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/month_report.dart';
import '../../../models/year_month.dart';
import '../../shared/widgets/category_tag.dart';

/// Read-only row: how one debt stood in [month].
class DebtStatusRow extends StatelessWidget {
  const DebtStatusRow({super.key, required this.status, required this.month});

  final DebtMonthStatus status;
  final YearMonth month;

  /// A one-off debt paid in a later month says when.
  String get _label {
    final debt = status.debt;
    final paidLater = debt.paidMonth;
    final text = status.isPaid
        ? 'Dibayar'
        : paidLater != null && month.isBefore(paidLater)
        ? 'Dibayar ${DateFormatter.monthName(paidLater.start)}'
        : 'Tak dibayar';
    return debt.isOverdueIn(month)
        ? 'Dari ${DateFormatter.monthName(debt.startMonth.start)} · $text'
        : text;
  }

  @override
  Widget build(BuildContext context) {
    final paid = status.isPaid;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            paid ? Icons.check_circle_rounded : Icons.cancel_outlined,
            size: 20,
            color: paid ? AppColors.green : AppColors.amber,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.debt.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    CategoryTag(category: status.debt.category),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: paid ? AppColors.textMuted : AppColors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            status.amount.asRinggit,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
