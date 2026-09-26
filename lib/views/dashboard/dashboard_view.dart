import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../viewmodels/cashflow_view_model.dart';
import '../../viewmodels/debt_view_model.dart';
import '../../viewmodels/expense_view_model.dart';
import '../../viewmodels/history_view_model.dart';
import '../../viewmodels/income_view_model.dart';
import '../expense/widgets/quick_expense_sheet.dart';
import '../history/history_view.dart';
import '../home_tab.dart';
import '../income/income_sheet.dart';
import '../settings/settings_view.dart';
import 'widgets/balance_hero.dart';
import 'widgets/daily_budget_card.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/stat_grid.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key, required this.onOpenTab});

  final ValueChanged<HomeTab> onOpenTab;

  @override
  Widget build(BuildContext context) {
    final summary = context.watch<CashflowViewModel>().summary;
    final debts = context.watch<DebtViewModel>();
    final todaySpent = context.select<ExpenseViewModel, double>(
      (vm) => vm.todayTotal,
    );
    final incomeCount = context.select<IncomeViewModel, int>(
      (vm) => vm.incomes.length,
    );
    final hasHistory = context.select<HistoryViewModel, bool>(
      (vm) => vm.pastMonths.isNotEmpty,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => showQuickExpenseSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Catat Belanja',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 104),
          children: [
            DashboardHeader(onOpenSettings: () => SettingsView.open(context)),
            const SizedBox(height: 20),
            TodayCard(daysRemaining: summary.daysRemaining),
            const SizedBox(height: 28),
            BalanceHero(summary: summary),
            const SizedBox(height: 24),
            DailyBudgetCard(
              summary: summary,
              onAddIncome: () => showIncomeSheet(context),
              onRestore: () => SettingsView.open(context),
            ),
            const SizedBox(height: 12),
            StatGrid(
              tiles: [
                StatTileData(
                  label: 'Duit',
                  // Keep this in sync with the Duit Kau sheet: spending from
                  // an account lowers its available balance immediately.
                  amount: summary.totalIncome - summary.totalExpense,
                  caption: incomeCount == 0
                      ? 'Tap untuk isi'
                      : '$incomeCount sumber',
                  icon: Icons.account_balance_wallet_outlined,
                  onTap: () => showIncomeSheet(context),
                ),
                StatTileData(
                  label: 'Hutang',
                  amount: summary.totalDebt,
                  caption: '${debts.paidCount}/${debts.count} selesai',
                  icon: Icons.receipt_long_outlined,
                  onTap: () => onOpenTab(HomeTab.debts),
                ),
                StatTileData(
                  label: 'Belanja',
                  amount: summary.totalExpense,
                  caption: 'Hari ni ${todaySpent.asRinggit}',
                  icon: Icons.payments_outlined,
                  onTap: () => onOpenTab(HomeTab.expenses),
                ),
              ],
            ),
            if (hasHistory) ...[
              const SizedBox(height: 24),
              Center(
                child: TextButton.icon(
                  onPressed: () => HistoryView.open(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                  icon: const Icon(Icons.history_rounded, size: 18),
                  label: const Text('Sejarah Bulanan'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
