import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:koyak/app.dart';
import 'package:koyak/app_dependencies.dart';
import 'package:koyak/models/expense_model.dart';
import 'package:koyak/models/income_model.dart';

import 'support/fake_backup_repository.dart';
import 'support/in_memory_repository.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ms'));

  Widget buildApp({
    List<IncomeModel> incomes = const [],
    List<ExpenseModel> expenses = const [],
  }) => KoyakApp(
    dependencies: AppDependencies(
      incomeRepository: InMemoryRepository(incomes),
      debtRepository: InMemoryRepository(),
      expenseRepository: InMemoryRepository(expenses),
      backupRepository: FakeBackupRepository(),
    ),
  );

  testWidgets('first run asks for salary', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Koyak'), findsOneWidget);
    expect(find.text('Baki Duit Semasa'), findsOneWidget);
    expect(find.text('Masukkan Gaji'), findsOneWidget);
  });

  testWidgets('with salary shows the daily limit sentence', (tester) async {
    await tester.pumpWidget(
      buildApp(
        incomes: [
          IncomeModel(
            id: 'g',
            source: 'Gaji',
            amount: 3000,
            date: DateTime.now(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Hari ni kau cuma boleh belanja', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('quick expense from the dashboard updates the balance', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        incomes: [
          IncomeModel(
            id: 'g',
            source: 'Gaji',
            amount: 1000,
            date: DateTime.now(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Catat Belanja'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '250');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('RM 750.00'), findsOneWidget);
  });

  testWidgets('last month shows up in history with its detail', (tester) async {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 15);
    await tester.pumpWidget(
      buildApp(
        incomes: [
          IncomeModel(id: 'g', source: 'Gaji', amount: 3000, date: lastMonth),
        ],
        expenses: [
          ExpenseModel(
            id: 'e',
            title: 'Nasi lemak',
            amount: 12,
            category: ExpenseCategory.makan,
            date: lastMonth,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // This month starts with last month's leftover carried in.
    expect(find.text('RM 2,988.00'), findsOneWidget);
    expect(find.textContaining('Termasuk baki'), findsOneWidget);
    expect(find.text('Masukkan Gaji'), findsNothing);

    await tester.tap(find.text('Analitik'));
    await tester.pumpAndSettle();
    final monthRow = find.text('Belanja RM 12.00');
    await tester.scrollUntilVisible(monthRow, 200);
    await tester.ensureVisible(monthRow);
    await tester.pumpAndSettle();
    await tester.tap(monthRow);
    await tester.pumpAndSettle();

    expect(find.text('Baki Akhir Bulan'), findsOneWidget);
    // Closing balance + the Baki legend in the salary split.
    expect(find.text('RM 2,988.00'), findsNWidgets(2));
    await tester.scrollUntilVisible(find.text('Nasi lemak'), 200);
    expect(find.text('Nasi lemak'), findsOneWidget);
  });
}
