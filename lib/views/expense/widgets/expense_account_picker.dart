import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/income_model.dart';
import '../../../viewmodels/expense_view_model.dart';
import '../../shared/category_style.dart';

/// Opens a searchable, touch-friendly account picker for an expense.
Future<String?> showExpenseAccountPicker(
  BuildContext context, {
  required List<IncomeModel> accounts,
  required ExpenseViewModel expenses,
  String? selectedAccount,
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (context) => _ExpenseAccountPicker(
    accounts: accounts,
    expenses: expenses,
    selectedAccount: selectedAccount,
  ),
);

class _ExpenseAccountPicker extends StatefulWidget {
  const _ExpenseAccountPicker({
    required this.accounts,
    required this.expenses,
    required this.selectedAccount,
  });

  final List<IncomeModel> accounts;
  final ExpenseViewModel expenses;
  final String? selectedAccount;

  @override
  State<_ExpenseAccountPicker> createState() => _ExpenseAccountPickerState();
}

class _ExpenseAccountPickerState extends State<_ExpenseAccountPicker> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final accounts = widget.accounts
        .where((account) => account.source.toLowerCase().contains(query))
        .toList();
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final availableHeight = MediaQuery.sizeOf(context).height - inset - 24;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + inset),
      child: Container(
        height: availableHeight * 0.82,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih akaun bayaran',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Baki akan ditolak daripada akaun ini.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Tutup',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                key: const ValueKey('expense-account-search'),
                controller: _search,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari Maybank, TNG, Tunai...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                          tooltip: 'Kosongkan carian',
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: accounts.isEmpty
                  ? const _NoAccountsFound()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: accounts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final account = accounts[index];
                        final balance =
                            account.amount -
                            widget.expenses.totalFromAccount(account.source);
                        final selected =
                            account.source == widget.selectedAccount;
                        return _AccountOption(
                          account: account,
                          balance: balance,
                          selected: selected,
                          onTap: () =>
                              Navigator.of(context).pop(account.source),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountOption extends StatelessWidget {
  const _AccountOption({
    required this.account,
    required this.balance,
    required this.selected,
    required this.onTap,
  });

  final IncomeModel account;
  final double balance;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.green : AppColors.textSecondary;
    final radius = BorderRadius.circular(18);
    return Material(
      color: selected
          ? AppColors.green.withValues(alpha: 0.12)
          : AppColors.surfaceRaised,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected
                  ? AppColors.green.withValues(alpha: 0.7)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(moneySourceIcon(account.source), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.source,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Baki tersedia',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                balance.asRinggit,
                style: TextStyle(fontWeight: FontWeight.w800, color: color),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoAccountsFound extends StatelessWidget {
  const _NoAccountsFound();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.search_off_rounded, size: 32, color: AppColors.textMuted),
        SizedBox(height: 8),
        Text('Akaun tak dijumpai'),
        SizedBox(height: 2),
        Text(
          'Cuba kata kunci lain.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    ),
  );
}
