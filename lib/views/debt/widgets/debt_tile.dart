import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/debt_model.dart';
import '../../../models/year_month.dart';
import '../../../viewmodels/debt_view_model.dart';
import '../../shared/widgets/category_tag.dart';
import '../../shared/widgets/koyak_snack.dart';
import 'debt_form_sheet.dart';

/// Checklist row: tap the circle to toggle paid, tap the row to edit,
/// swipe left to delete.
class DebtTile extends StatelessWidget {
  const DebtTile({super.key, required this.debt});

  final DebtModel debt;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<DebtViewModel>();
    final isPaid = vm.isPaid(debt);
    final radius = BorderRadius.circular(16);
    final due = _DueLabel.of(debt, isPaid: isPaid, now: DateTime.now());

    return Dismissible(
      key: ValueKey('debt-${debt.id}'),
      direction: DismissDirection.endToStart,
      background: const _DeleteBackground(),
      onDismissed: (_) {
        vm.remove(debt.id);
        showKoyakSnack(
          context,
          '"${debt.title}" dipadam',
          onUndo: () => vm.upsert(debt),
        );
      },
      child: Material(
        color: AppColors.surface,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: () => showDebtFormSheet(context, debt: debt),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 16, 10),
            child: Row(
              children: [
                _PaidCheckbox(
                  isPaid: isPaid,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    vm.togglePaid(debt.id);
                  },
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isPaid
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                          decoration: isPaid
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          CategoryTag(category: debt.category),
                          if (due != null) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                due.text,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: due.color,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  debt.amountIn(vm.currentMonth).asRinggit,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isPaid ? AppColors.green : AppColors.textPrimary,
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

class _PaidCheckbox extends StatelessWidget {
  const _PaidCheckbox({required this.isPaid, required this.onTap});

  final bool isPaid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: isPaid,
      label: isPaid ? 'Selesai' : 'Belum bayar',
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPaid ? AppColors.green : Colors.transparent,
                border: Border.all(
                  color: isPaid ? AppColors.green : AppColors.textMuted,
                  width: 1.6,
                ),
              ),
              child: isPaid
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.background,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Due-date hint beside the tag; amber when late or within 3 days.
class _DueLabel {
  const _DueLabel(this.text, this.color);

  final String text;
  final Color color;

  static const _soonThresholdDays = 3;

  static _DueLabel? of(
    DebtModel debt, {
    required bool isPaid,
    required DateTime now,
  }) {
    if (isPaid) return const _DueLabel('Dah bayar', AppColors.textMuted);

    final days = debt.daysUntilDue(now);
    final dueDate = debt.dueDateIn(YearMonth.of(now));
    if (days == null || dueDate == null) return null;
    if (days < 0) return _DueLabel('Lewat ${-days} hari', AppColors.amber);
    if (days == 0) return const _DueLabel('Due hari ni', AppColors.amber);
    if (days <= _soonThresholdDays) {
      return _DueLabel('$days hari lagi', AppColors.amber);
    }
    return _DueLabel(
      'Sebelum ${DateFormatter.short(dueDate)}',
      AppColors.textMuted,
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete_outline_rounded, color: AppColors.amber),
    );
  }
}
