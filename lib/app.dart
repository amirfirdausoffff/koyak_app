import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app_dependencies.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'viewmodels/backup_view_model.dart';
import 'viewmodels/cashflow_view_model.dart';
import 'viewmodels/debt_view_model.dart';
import 'viewmodels/expense_view_model.dart';
import 'viewmodels/history_view_model.dart';
import 'viewmodels/income_view_model.dart';
import 'views/home_shell.dart';

class KoyakApp extends StatelessWidget {
  const KoyakApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => IncomeViewModel(dependencies.incomeRepository)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => DebtViewModel(dependencies.debtRepository)..load(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ExpenseViewModel(dependencies.expenseRepository)..load(),
        ),
        ChangeNotifierProvider(
          create: (context) => CashflowViewModel(
            incomes: context.read(),
            debts: context.read(),
            expenses: context.read(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => HistoryViewModel(
            incomes: context.read(),
            debts: context.read(),
            expenses: context.read(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => BackupViewModel(
            dependencies.backupRepository,
            onDataRestored: () => Future.wait([
              context.read<IncomeViewModel>().load(),
              context.read<DebtViewModel>().load(),
              context.read<ExpenseViewModel>().load(),
            ]),
          ),
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        locale: const Locale('ms', 'MY'),
        supportedLocales: const [Locale('ms', 'MY'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const HomeShell(),
      ),
    );
  }
}
