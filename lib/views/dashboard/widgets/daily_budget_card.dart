import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/cashflow_summary.dart';
import '../../shared/widgets/section_card.dart';

class DailyBudgetCard extends StatelessWidget {
  const DailyBudgetCard({
    super.key,
    required this.summary,
    required this.onAddIncome,
    required this.onRestore,
  });

  final CashflowSummary summary;
  final VoidCallback onAddIncome;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    if (!summary.hasFunds) {
      return _NoIncomeCard(onAddIncome: onAddIncome, onRestore: onRestore);
    }
    if (summary.dailyLimit <= 0) return _BudgetGoneCard(summary: summary);

    final textTheme = Theme.of(context).textTheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel(
            icon: Icons.today_rounded,
            text: 'Had Belanja Hari Ni',
            color: AppColors.green,
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Hari ni kau cuma boleh belanja '),
                TextSpan(
                  text: summary.dailyLimit.asRinggit,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const TextSpan(text: ' supaya tak '),
                const TextSpan(
                  text: 'KOYAK',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const TextSpan(text: '.'),
              ],
            ),
            style: textTheme.titleMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 10),
          Text(
            'Baki ${summary.netRemaining.asRinggit} ÷ '
            '${summary.daysRemaining} hari lagi bulan ni',
            style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _NoIncomeCard extends StatelessWidget {
  const _NoIncomeCard({required this.onAddIncome, required this.onRestore});

  final VoidCallback onAddIncome;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardLabel(
            icon: Icons.account_balance_wallet_outlined,
            text: 'Mula Di Sini',
            color: AppColors.green,
          ),
          const SizedBox(height: 12),
          Text(
            'Masukkan gaji bulan ni dulu. Lepas tu Koyak kira berapa '
            'kau boleh belanja sehari.',
            style: textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAddIncome,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Masukkan Gaji'),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: onRestore,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            icon: const Icon(Icons.cloud_download_outlined, size: 18),
            label: const Text('Restore backup dari Google Drive'),
          ),
        ],
      ),
    );
  }
}

class _BudgetGoneCard extends StatelessWidget {
  const _BudgetGoneCard({required this.summary});

  final CashflowSummary summary;

  @override
  Widget build(BuildContext context) {
    final message = summary.isKoyak
        ? 'Kau dah terlebih ${summary.netRemaining.abs().asRinggit}. '
              'Tahan belanja sampai gaji masuk.'
        : 'Baki dah habis. Tahan belanja sampai gaji masuk.';
    return SectionCard(
      borderColor: AppColors.amber.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardLabel(
            icon: Icons.warning_amber_rounded,
            text: 'Bajet Harian Dah Habis',
            color: AppColors.amber,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _CardLabel extends StatelessWidget {
  const _CardLabel({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
