import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/debt_model.dart';
import '../../viewmodels/debt_view_model.dart';
import '../shared/category_style.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/page_header.dart';
import '../shared/widgets/section_card.dart';
import 'widgets/debt_form_sheet.dart';
import 'widgets/debt_tile.dart';

class DebtTrackerView extends StatelessWidget {
  const DebtTrackerView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DebtViewModel>();
    final debts = vm.debts;
    final overdue = vm.overdue;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        tooltip: 'Tambah hutang',
        onPressed: () => showDebtFormSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 104),
          children: [
            PageHeader(
              title: 'Hutang',
              subtitle:
                  'Bayaran ${DateFormatter.month(vm.currentMonth.start)}. '
                  'Bulan depan reset sendiri.',
            ),
            if (debts.isEmpty && overdue.isEmpty)
              const EmptyState(
                icon: Icons.task_alt_rounded,
                title: 'Tiada hutang direkod',
                message:
                    'Tambah komitmen bulanan (PTPTN, kereta, kad kredit) '
                    'atau hutang sekali bayar (hutang kawan).',
              ),
            if (debts.isNotEmpty) ...[
              _DebtProgressCard(vm: vm),
              const SizedBox(height: 20),
              for (final debt in debts)
                Padding(
                  key: ValueKey(debt.id),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DebtTile(debt: debt),
                ),
            ],
            if (overdue.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.only(top: debts.isEmpty ? 0 : 16),
                child: const _SectionHeading(
                  title: 'Tertunggak',
                  subtitle:
                      'Hutang sekali bayar dari bulan lepas. Dah ditolak '
                      'dari baki bulan asal, jadi tak dikira lagi bulan ni.',
                ),
              ),
              const SizedBox(height: 12),
              for (final debt in overdue)
                Padding(
                  key: ValueKey(debt.id),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DebtTile(debt: debt),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DebtProgressCard extends StatelessWidget {
  const _DebtProgressCard({required this.vm});

  final DebtViewModel vm;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Dah Bayar',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${vm.paidCount}/${vm.count} selesai',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: vm.paidAmount.asRinggit,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: '  / ${vm.totalAmount.asRinggit}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: vm.progress, minHeight: 8),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final category in DebtCategory.values)
                Expanded(
                  child: _CategoryTotal(
                    category: category,
                    amount: vm.totalFor(category),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _CategoryTotal extends StatelessWidget {
  const _CategoryTotal({required this.category, required this.amount});

  final DebtCategory category;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: category.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            '${category.shortLabel}  ${amount.asRinggit}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
