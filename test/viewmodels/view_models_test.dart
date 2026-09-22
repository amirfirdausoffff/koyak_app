import 'package:flutter_test/flutter_test.dart';
import 'package:koyak/models/debt_model.dart';
import 'package:koyak/models/expense_model.dart';
import 'package:koyak/models/income_model.dart';
import 'package:koyak/models/year_month.dart';
import 'package:koyak/viewmodels/cashflow_ledger.dart';
import 'package:koyak/viewmodels/cashflow_view_model.dart';
import 'package:koyak/viewmodels/debt_view_model.dart';
import 'package:koyak/viewmodels/expense_view_model.dart';
import 'package:koyak/viewmodels/history_view_model.dart';
import 'package:koyak/viewmodels/income_view_model.dart';

import '../support/in_memory_repository.dart';

void main() {
  late DateTime now;
  DateTime clock() => now;

  setUp(() => now = DateTime(2026, 9, 21, 12));

  group('CashflowViewModel.calculate', () {
    test('Baki = Gaji − Hutang − Belanja; daily limit over remaining days', () {
      final summary = CashflowLedger.calculate(
        totalIncome: 4000,
        totalDebt: 1300,
        totalExpense: 700,
        daysRemaining: 10,
      );
      expect(summary.netRemaining, 2000);
      expect(summary.dailyLimit, 200);
      expect(summary.isKoyak, isFalse);
    });

    test('overspent month has zero daily limit and is KOYAK', () {
      final summary = CashflowLedger.calculate(
        totalIncome: 1000,
        totalDebt: 800,
        totalExpense: 500,
        daysRemaining: 10,
      );
      expect(summary.netRemaining, -300);
      expect(summary.dailyLimit, 0);
      expect(summary.isKoyak, isTrue);
    });

    test('a finished month has no daily limit', () {
      final summary = CashflowLedger.calculate(
        totalIncome: 1000,
        totalDebt: 0,
        totalExpense: 0,
      );
      expect(summary.dailyLimit, 0);
    });
  });

  group('DebtViewModel', () {
    late InMemoryRepository<DebtModel> repo;
    late DebtViewModel vm;

    setUp(() async {
      repo = InMemoryRepository([
        DebtModel(
          id: 'a',
          title: 'Kereta',
          amount: 800,
          category: DebtCategory.halal,
          createdAt: DateTime(2026, 8, 1),
          payments: const {'2026-09': 800},
          dueDate: DateTime(2026, 9, 5),
        ),
        DebtModel(
          id: 'b',
          title: 'Hutang Ali',
          amount: 200,
          category: DebtCategory.risky,
          createdAt: DateTime(2026, 9, 2),
        ),
      ]);
      vm = DebtViewModel(repo, clock: clock);
      await vm.load();
    });

    test('totals and progress for this month', () {
      expect(vm.totalAmount, 1000);
      expect(vm.paidAmount, 800);
      expect(vm.progress, 0.8);
      expect(vm.totalFor(DebtCategory.risky), 200);
    });

    test('unpaid debts are listed first', () {
      expect(vm.debts.map((d) => d.id), ['b', 'a']);
    });

    test('togglePaid records this month and persists', () async {
      await vm.togglePaid('b');
      expect(vm.paidCount, 2);
      final saved = repo.saved.firstWhere((d) => d.id == 'b');
      expect(saved.isPaidIn(const YearMonth(2026, 9)), isTrue);
    });

    test('next month starts unpaid on its own, list kept', () {
      now = DateTime(2026, 10, 1);
      expect(vm.count, 2);
      expect(vm.paidCount, 0);
      expect(vm.debts.first.id, 'a'); // due 5 Oct sorts before undated
    });

    test('debt added this month is deleted outright', () async {
      await vm.remove('b');
      expect(repo.saved.map((d) => d.id), ['a']);
    });

    test('older debt is ended, so past months still show it', () async {
      now = DateTime(2026, 10, 3);
      await vm.remove('a');
      expect(vm.debts.map((d) => d.id), ['b']);
      expect(
        vm.debtsIn(const YearMonth(2026, 9)).map((d) => d.id),
        contains('a'),
      );
    });
  });

  group('DebtViewModel kinds', () {
    late InMemoryRepository<DebtModel> repo;
    late DebtViewModel vm;

    setUp(() async {
      repo = InMemoryRepository([
        DebtModel(
          id: 'kereta',
          title: 'Kereta',
          amount: 800,
          category: DebtCategory.halal,
          createdAt: DateTime(2026, 9, 1),
          lastMonth: const YearMonth(2026, 10),
        ),
        DebtModel(
          id: 'ali',
          title: 'Hutang Ali',
          amount: 200,
          category: DebtCategory.risky,
          createdAt: DateTime(2026, 9, 2),
          kind: DebtKind.once,
        ),
      ]);
      vm = DebtViewModel(repo, clock: clock);
      await vm.load();
    });

    test('an unpaid one-off debt is tertunggak next month, not in totals', () {
      now = DateTime(2026, 10, 1);
      expect(vm.debts.map((d) => d.id), ['kereta']);
      expect(vm.overdue.map((d) => d.id), ['ali']);
      expect(vm.totalAmount, 800);
    });

    test('paying it this month keeps it listed, then it is gone', () async {
      now = DateTime(2026, 10, 1);
      await vm.togglePaid('ali');
      expect(vm.isPaid(vm.overdue.single), isTrue);

      now = DateTime(2026, 11, 1);
      expect(vm.overdue, isEmpty);
    });

    test('a monthly debt disappears after its last month', () {
      now = DateTime(2026, 11, 1);
      expect(vm.debts, isEmpty);
      expect(vm.debtsIn(const YearMonth(2026, 10)).map((d) => d.id), [
        'kereta',
      ]);
    });

    test('add stores the kind and ignores a last month for one-offs', () async {
      await vm.add(
        title: 'Pinjam Abu',
        amount: 50,
        category: DebtCategory.risky,
        kind: DebtKind.once,
        lastMonth: const YearMonth(2027, 1),
      );
      final saved = repo.saved.firstWhere((d) => d.title == 'Pinjam Abu');
      expect(saved.kind, DebtKind.once);
      expect(saved.lastMonth, isNull);
    });
  });

  group('ExpenseViewModel', () {
    late ExpenseViewModel vm;

    setUp(() async {
      vm = ExpenseViewModel(InMemoryRepository(), clock: clock);
      await vm.load();
    });

    test('blank title falls back to the category name', () async {
      final expense = await vm.add(
        amount: 12,
        category: ExpenseCategory.minyak,
      );
      expect(expense.title, 'Minyak');
      expect(vm.todayTotal, 12);
    });

    test('category breakdown is sorted with percentages', () async {
      await vm.add(amount: 30, category: ExpenseCategory.makan);
      await vm.add(amount: 60, category: ExpenseCategory.bil);
      await vm.add(amount: 10, category: ExpenseCategory.makan);

      final shares = vm.categoryBreakdown;
      expect(shares.map((s) => s.category), [
        ExpenseCategory.bil,
        ExpenseCategory.makan,
      ]);
      expect(shares.first.percentage, 60);
      expect(shares.last.amount, 40);
    });

    test('a new month starts at zero without deleting the old one', () async {
      await vm.add(amount: 50, category: ExpenseCategory.makan);
      now = DateTime(2026, 10, 1, 8);

      expect(vm.total, 0);
      expect(vm.timeline, isEmpty);
      expect(vm.totalIn(const YearMonth(2026, 9)), 50);
    });
  });

  group('Cashflow + history across months', () {
    late IncomeViewModel incomes;
    late DebtViewModel debts;
    late ExpenseViewModel expenses;
    late CashflowViewModel cashflow;
    late HistoryViewModel history;

    setUp(() async {
      incomes = IncomeViewModel(
        InMemoryRepository([
          IncomeModel(
            id: 'g',
            source: 'Gaji',
            amount: 3000,
            date: DateTime(2026, 9, 1),
          ),
        ]),
        clock: clock,
      );
      debts = DebtViewModel(
        InMemoryRepository([
          DebtModel(
            id: 'd',
            title: 'PTPTN',
            amount: 500,
            category: DebtCategory.halal,
            createdAt: DateTime(2026, 9, 1),
            payments: const {'2026-09': 500},
          ),
        ]),
        clock: clock,
      );
      expenses = ExpenseViewModel(InMemoryRepository(), clock: clock);
      cashflow = CashflowViewModel(
        incomes: incomes,
        debts: debts,
        expenses: expenses,
        clock: clock,
      );
      history = HistoryViewModel(
        incomes: incomes,
        debts: debts,
        expenses: expenses,
        clock: clock,
      );
      await Future.wait([incomes.load(), debts.load(), expenses.load()]);
    });

    tearDown(() {
      cashflow.dispose();
      history.dispose();
    });

    test('recalculates live when an expense is added', () async {
      expect(cashflow.isReady, isTrue);
      expect(cashflow.summary.netRemaining, 2500);

      await expenses.add(amount: 500, category: ExpenseCategory.makan);
      expect(cashflow.summary.netRemaining, 2000);
      expect(cashflow.summary.dailyLimit, 200); // 2000 ÷ 10 days left
    });

    test(
      'new month: dashboard starts fresh, September moves to history',
      () async {
        await expenses.add(amount: 200, category: ExpenseCategory.makan);
        expect(history.pastMonths, isEmpty);

        now = DateTime(2026, 10, 1, 9);
        cashflow.refresh();

        expect(cashflow.summary.totalIncome, 0);
        expect(cashflow.summary.totalExpense, 0);
        expect(cashflow.summary.totalDebt, 500); // commitment carries on
        expect(debts.paidCount, 0);
        // September's leftover carries in: 3000 − 500 − 200 = 2300.
        expect(cashflow.summary.carriedForward, 2300);
        expect(cashflow.summary.netRemaining, 2300 - 500);

        final past = history.pastMonths.single;
        expect(past.month, const YearMonth(2026, 9));
        expect(past.summary.netRemaining, 2300);
      },
    );

    test('month report has everything that happened that month', () async {
      await expenses.add(amount: 45, category: ExpenseCategory.minyak);
      now = DateTime(2026, 10, 2);

      final report = history.reportFor(const YearMonth(2026, 9));
      expect(report.incomes.single.source, 'Gaji');
      expect(report.debts.single.isPaid, isTrue);
      expect(report.overdue, isEmpty);
      expect(report.expenseCount, 1);
      expect(report.categoryShares.single.category, ExpenseCategory.minyak);
    });

    test('month report lists tertunggak one-offs separately', () async {
      await debts.add(
        title: 'Hutang Ali',
        amount: 200,
        category: DebtCategory.risky,
        kind: DebtKind.once,
      );
      now = DateTime(2026, 11, 2);

      final sep = history.reportFor(const YearMonth(2026, 9));
      expect(sep.debts.map((d) => d.debt.title), contains('Hutang Ali'));
      expect(sep.overdue, isEmpty);

      final oct = history.reportFor(const YearMonth(2026, 10));
      expect(oct.debts.map((d) => d.debt.title), ['PTPTN']);
      expect(oct.overdue.single.debt.title, 'Hutang Ali');
      expect(oct.overdue.single.isPaid, isFalse);
    });
  });

  group('CashflowLedger carry forward', () {
    late IncomeViewModel incomes;
    late DebtViewModel debts;
    late ExpenseViewModel expenses;
    late CashflowLedger ledger;

    Future<void> build({
      List<IncomeModel> incomeList = const [],
      List<DebtModel> debtList = const [],
      List<ExpenseModel> expenseList = const [],
    }) async {
      incomes = IncomeViewModel(InMemoryRepository(incomeList), clock: clock);
      debts = DebtViewModel(InMemoryRepository(debtList), clock: clock);
      expenses = ExpenseViewModel(
        InMemoryRepository(expenseList),
        clock: clock,
      );
      await Future.wait([incomes.load(), debts.load(), expenses.load()]);
      ledger = CashflowLedger(
        incomes: incomes,
        debts: debts,
        expenses: expenses,
      );
    }

    IncomeModel pay(DateTime date, double amount) =>
        IncomeModel(id: '$date', source: 'Gaji', amount: amount, date: date);

    ExpenseModel spend(DateTime date, double amount) => ExpenseModel(
      id: '$date',
      title: 'x',
      amount: amount,
      category: ExpenseCategory.makan,
      date: date,
    );

    test('salary on the 25th keeps working next month', () async {
      await build(
        incomeList: [pay(DateTime(2026, 9, 25), 4000)],
        expenseList: [
          spend(DateTime(2026, 9, 28), 100),
          spend(DateTime(2026, 10, 3), 300),
        ],
      );
      final oct = ledger.summaryFor(const YearMonth(2026, 10));
      expect(oct.carriedForward, 3900);
      expect(oct.totalIncome, 0);
      expect(oct.netRemaining, 3600);
      expect(oct.hasFunds, isTrue);
    });

    test('balance keeps rolling over several months', () async {
      await build(
        incomeList: [
          pay(DateTime(2026, 8, 25), 3000),
          pay(DateTime(2026, 9, 25), 3000),
        ],
        expenseList: [
          spend(DateTime(2026, 8, 30), 1000),
          spend(DateTime(2026, 9, 15), 2500),
        ],
      );
      expect(ledger.carriedInto(const YearMonth(2026, 9)), 2000);
      expect(ledger.carriedInto(const YearMonth(2026, 10)), 2500);
    });

    test('an overspent month carries a negative balance', () async {
      await build(
        incomeList: [pay(DateTime(2026, 9, 1), 1000)],
        expenseList: [spend(DateTime(2026, 9, 20), 1200)],
      );
      final oct = ledger.summaryFor(const YearMonth(2026, 10));
      expect(oct.carriedForward, -200);
      expect(oct.isKoyak, isTrue);
    });

    test('nothing carries from before the first salary', () async {
      await build(
        debtList: [
          DebtModel(
            id: 'd',
            title: 'Kereta',
            amount: 800,
            category: DebtCategory.halal,
            createdAt: DateTime(2026, 8, 10),
          ),
        ],
        incomeList: [pay(DateTime(2026, 9, 25), 4000)],
      );
      // August had only the debt — it must not open September in the red.
      expect(ledger.carriedInto(const YearMonth(2026, 9)), 0);
      expect(ledger.carriedInto(const YearMonth(2026, 10)), 4000 - 800);
    });

    test('a tertunggak one-off debt is taken off the baki only once', () async {
      await build(
        incomeList: [pay(DateTime(2026, 9, 1), 1000)],
        debtList: [
          DebtModel(
            id: 'ali',
            title: 'Hutang Ali',
            amount: 200,
            category: DebtCategory.risky,
            createdAt: DateTime(2026, 9, 2),
            kind: DebtKind.once,
            payments: const {'2026-11': 200}, // finally paid in November
          ),
        ],
      );
      expect(ledger.summaryFor(const YearMonth(2026, 9)).totalDebt, 200);
      for (final month in const [YearMonth(2026, 10), YearMonth(2026, 11)]) {
        final summary = ledger.summaryFor(month);
        expect(summary.totalDebt, 0);
        expect(summary.netRemaining, 800);
      }
    });

    test('a monthly debt stops costing after its last month', () async {
      await build(
        incomeList: [pay(DateTime(2026, 9, 1), 3000)],
        debtList: [
          DebtModel(
            id: 'k',
            title: 'Kereta',
            amount: 500,
            category: DebtCategory.halal,
            createdAt: DateTime(2026, 9, 1),
            lastMonth: const YearMonth(2026, 10),
          ),
        ],
      );
      expect(ledger.summaryFor(const YearMonth(2026, 10)).totalDebt, 500);
      final nov = ledger.summaryFor(const YearMonth(2026, 11));
      expect(nov.totalDebt, 0);
      expect(nov.netRemaining, 2000);
    });
  });

  group('IncomeViewModel money sources', () {
    late IncomeViewModel vm;

    setUp(() async {
      vm = IncomeViewModel(
        InMemoryRepository([
          IncomeModel(
            id: 'gx',
            source: 'GX Bank',
            amount: 2,
            date: DateTime(2026, 9, 3),
          ),
        ]),
        clock: clock,
      );
      await vm.load();
    });

    test('top up adds to the balance and keeps the month', () async {
      await vm.adjust(
        'gx',
        source: 'GX Bank',
        value: 10,
        change: AmountChange.add,
      );
      final gx = vm.incomes.single;
      expect(gx.amount, 12);
      expect(gx.date, DateTime(2026, 9, 3));
    });

    test('replace sets a new balance, even zero, and can rename', () async {
      await vm.adjust(
        'gx',
        source: 'GXBank',
        value: 0,
        change: AmountChange.replace,
      );
      expect(vm.incomes.single.amount, 0);
      expect(vm.incomes.single.source, 'GXBank');
    });

    test('finds this month\'s source by name, ignoring case', () {
      expect(vm.sourceNamed('gx bank')?.id, 'gx');
      expect(vm.sourceNamed('Maybank'), isNull);
    });
  });
}
