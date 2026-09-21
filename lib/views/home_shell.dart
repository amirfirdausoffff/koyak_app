import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../viewmodels/backup_view_model.dart';
import '../viewmodels/cashflow_view_model.dart';
import '../viewmodels/debt_view_model.dart';
import '../viewmodels/expense_view_model.dart';
import '../viewmodels/income_view_model.dart';
import 'analytics/analytics_view.dart';
import 'dashboard/dashboard_view.dart';
import 'debt/debt_tracker_view.dart';
import 'expense/expense_log_view.dart';
import 'home_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  HomeTab _tab = HomeTab.dashboard;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Everything is scoped to today's month, so a resume on a new day (or
    // month) must redraw. The background backup may also have run.
    if (state == AppLifecycleState.resumed) {
      context.read<IncomeViewModel>().refresh();
      context.read<DebtViewModel>().refresh();
      context.read<ExpenseViewModel>().refresh();
      context.read<CashflowViewModel>().refresh();
      context.read<BackupViewModel>().refresh();
    }
  }

  void _open(HomeTab tab) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final isReady = context.select<CashflowViewModel, bool>((vm) => vm.isReady);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
      ),
      child: Scaffold(
        body: isReady
            ? IndexedStack(
                index: _tab.index,
                children: [
                  DashboardView(onOpenTab: _open),
                  const DebtTrackerView(),
                  const ExpenseLogView(),
                  const AnalyticsView(),
                ],
              )
            : const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab.index,
          onDestinationSelected: (index) => _open(HomeTab.values[index]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Utama',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist_rounded),
              label: 'Hutang',
            ),
            NavigationDestination(
              icon: Icon(Icons.payments_outlined),
              selectedIcon: Icon(Icons.payments_rounded),
              label: 'Belanja',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Analitik',
            ),
          ],
        ),
      ),
    );
  }
}
