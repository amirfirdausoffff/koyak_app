import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:koyak/app.dart';
import 'package:koyak/app_dependencies.dart';
import 'package:koyak/models/debt_model.dart';
import 'package:koyak/models/expense_model.dart';
import 'package:koyak/models/income_model.dart';
import 'package:koyak/models/year_month.dart';

import 'support/fake_backup_repository.dart';
import 'support/in_memory_repository.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ms'));

  Widget buildApp({
    List<IncomeModel> incomes = const [],
    List<ExpenseModel> expenses = const [],
    List<DebtModel> debts = const [],
  }) => KoyakApp(
    dependencies: AppDependencies(
      incomeRepository: InMemoryRepository(incomes),
      debtRepository: InMemoryRepository(debts),
      expenseRepository: InMemoryRepository(expenses),
      backupRepository: FakeBackupRepository(),
    ),
  );

  testWidgets('first run asks for salary', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Koyak'), findsOneWidget);
    expect(find.text('Boleh Belanja Lagi'), findsOneWidget);
    expect(find.text('Masukkan Duit'), findsOneWidget);
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
    await _selectExpenseAccount(tester, 'Gaji');
    await tester.tap(find.byKey(const ValueKey('save-expense')));
    await tester.pumpAndSettle();

    // Nothing is saved until the confirmation dialog is accepted.
    expect(find.text('Simpan Belanja?'), findsOneWidget);
    await tester.tap(_inDialog('Simpan'));
    await tester.pumpAndSettle();

    // Baki utama dan card Duit both update after the expense is saved.
    expect(find.text('RM 750.00'), findsNWidgets(2));
  });

  testWidgets('expense account picker searches accounts', (tester) async {
    await tester.pumpWidget(
      buildApp(
        incomes: [
          IncomeModel(
            id: 'g',
            source: 'Gaji',
            amount: 1000,
            date: DateTime.now(),
          ),
          IncomeModel(
            id: 't',
            source: 'Tunai',
            amount: 80,
            date: DateTime.now(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Catat Belanja'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('expense-account-picker')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('expense-account-search')),
      'tunai',
    );
    await tester.pumpAndSettle();

    expect(find.text('Tunai'), findsOneWidget);
    expect(find.text('Gaji'), findsNothing);
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
    // Hero and card Duit both show the carried cash balance.
    expect(find.text('RM 2,988.00'), findsNWidgets(2));
    expect(find.textContaining('Termasuk baki'), findsOneWidget);
    expect(find.text('Masukkan Duit'), findsNothing);

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

  testWidgets('cancelling the save dialog keeps the balance', (tester) async {
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
    await _selectExpenseAccount(tester, 'Gaji');
    await tester.tap(find.byKey(const ValueKey('save-expense')));
    await tester.pumpAndSettle();
    await tester.tap(_inDialog('Batal'));
    await tester.pumpAndSettle();

    expect(find.text('Simpan Belanja?'), findsNothing);
    // The quick sheet stays open with the amount, ready to fix.
    expect(find.text('250'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10)); // dismiss the sheet
    await tester.pumpAndSettle();
    expect(find.text('RM 1,000.00'), findsWidgets);
  });

  testWidgets('swipe-to-delete asks first', (tester) async {
    await tester.pumpWidget(
      buildApp(
        expenses: [
          ExpenseModel(
            id: 'e',
            title: 'Nasi lemak',
            amount: 12,
            category: ExpenseCategory.makan,
            date: DateTime.now(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Belanja'));
    await tester.pumpAndSettle();

    final row = find.text('Nasi lemak');
    // The form's text fields are scrollables too; scroll the page itself.
    await tester.scrollUntilVisible(
      row,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();

    await tester.drag(row, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Padam Belanja?'), findsOneWidget);
    await tester.tap(_inDialog('Batal'));
    await tester.pumpAndSettle();
    expect(find.text('Nasi lemak'), findsOneWidget);

    await tester.drag(row, const Offset(-500, 0));
    await tester.pumpAndSettle();
    await tester.tap(_inDialog('Padam'));
    await tester.pumpAndSettle();
    expect(find.text('Nasi lemak'), findsNothing);
  });

  testWidgets('full expense history can search by account', (tester) async {
    await tester.pumpWidget(
      buildApp(
        expenses: [
          ExpenseModel(
            id: 'food',
            title: 'Nasi lemak',
            amount: 12,
            category: ExpenseCategory.makan,
            account: 'Maybank',
            date: DateTime.now(),
          ),
          ExpenseModel(
            id: 'fuel',
            title: 'Petrol',
            amount: 50,
            category: ExpenseCategory.minyak,
            account: 'Touch n Go',
            date: DateTime.now(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Belanja'));
    await tester.pumpAndSettle();

    final fullHistory = find.text('Lihat sejarah penuh');
    await tester.scrollUntilVisible(
      fullHistory,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(fullHistory);
    await tester.pumpAndSettle();

    expect(find.text('Sejarah Belanja'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('expense-history-search')),
      'maybank',
    );
    await tester.pumpAndSettle();
    expect(find.text('Nasi lemak'), findsOneWidget);
    expect(find.text('Petrol'), findsNothing);
  });

  testWidgets('topping up an existing money source', (tester) async {
    await tester.pumpWidget(
      buildApp(
        incomes: [
          IncomeModel(
            id: 'gx',
            source: 'GX Bank',
            amount: 2,
            date: DateTime.now(),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Duit'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Duit Kau'), findsOneWidget);

    // First match is the source card; the other is the "GX Bank" chip.
    await tester.tap(find.text('GX Bank').first);
    await tester.pumpAndSettle();
    expect(find.text('Kemaskini Sumber'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).last, '10');
    await tester.pump();
    expect(find.text('Jumlah lepas simpan: RM 12.00'), findsOneWidget);

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Kemaskini GX Bank?'), findsOneWidget);
    await tester.tap(_inDialog('Simpan'));
    await tester.pumpAndSettle();

    // Back on the sources list with the new balance.
    expect(find.text('Kemaskini Sumber'), findsNothing);
    expect(find.text('RM 12.00'), findsWidgets);
  });

  testWidgets('adding a one-off debt', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hutang').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tambah hutang'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Hutang Ali');
    expect(find.text('Bulan terakhir bayar (pilihan)'), findsOneWidget);
    await tester.tap(find.text('Sekali je'));
    await tester.pumpAndSettle();
    // A one-off debt has no last month.
    expect(find.text('Bulan terakhir bayar (pilihan)'), findsNothing);
    await tester.enterText(find.byType(TextFormField).at(1), '200');

    final save = find.widgetWithText(FilledButton, 'Simpan');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Simpan Hutang?'), findsOneWidget);
    await tester.tap(_inDialog('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Hutang Ali'), findsOneWidget);
    expect(find.text('Sekali bayar'), findsOneWidget);
  });

  testWidgets('debt history shows past months and finished debts', (
    tester,
  ) async {
    final thisMonth = YearMonth.of(DateTime.now());
    final lastMonth = thisMonth.previous;
    final twoAgo = lastMonth.previous;
    await tester.pumpWidget(
      buildApp(
        debts: [
          DebtModel(
            id: 'k',
            title: 'Kereta',
            amount: 800,
            category: DebtCategory.halal,
            createdAt: twoAgo.start,
            lastMonth: lastMonth,
            payments: {twoAgo.key: 800, lastMonth.key: 800},
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hutang').first);
    await tester.pumpAndSettle();
    expect(find.text('Kereta'), findsNothing); // past its last month

    await tester.tap(find.byTooltip('Sejarah hutang'));
    await tester.pumpAndSettle();
    expect(find.text('Sejarah Hutang'), findsOneWidget);
    expect(find.text('1/1 dibayar'), findsNWidgets(2));
    await tester.scrollUntilVisible(find.text('Hutang Selesai'), 200);
    expect(find.textContaining('2/2 bayaran'), findsOneWidget);
    expect(find.text('RM 1,600.00'), findsOneWidget);
  });
}

Finder _inDialog(String text) =>
    find.descendant(of: find.byType(Dialog), matching: find.text(text));

Future<void> _selectExpenseAccount(WidgetTester tester, String account) async {
  await tester.tap(find.byKey(const ValueKey('expense-account-picker')));
  await tester.pumpAndSettle();
  expect(find.text('Pilih akaun bayaran'), findsOneWidget);
  await tester.tap(find.text(account).last);
  await tester.pumpAndSettle();
}
