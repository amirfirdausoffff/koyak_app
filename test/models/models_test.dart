import 'package:flutter_test/flutter_test.dart';
import 'package:koyak/models/cashflow_summary.dart';
import 'package:koyak/models/debt_model.dart';
import 'package:koyak/models/expense_model.dart';
import 'package:koyak/models/income_model.dart';
import 'package:koyak/models/year_month.dart';

void main() {
  const sep = YearMonth(2026, 9);
  const oct = YearMonth(2026, 10);

  group('JSON round-trip', () {
    test('IncomeModel', () {
      final income = IncomeModel(
        id: 'i1',
        source: 'Gaji',
        amount: 4200,
        date: DateTime(2026, 9, 1, 9),
      );
      expect(IncomeModel.fromJson(income.toJson()), income);
      expect(IncomeModel.fromMap(income.toMap()), income);
    });

    test('DebtModel with payments, due date and end date', () {
      final debt = DebtModel(
        id: 'd1',
        title: 'PTPTN',
        amount: 150,
        category: DebtCategory.halal,
        createdAt: DateTime(2026, 8, 3),
        dueDate: DateTime(2026, 9, 15),
        payments: const {'2026-08': 150, '2026-09': 150},
        endedAt: DateTime(2026, 10, 2),
      );
      final noDate = DebtModel(
        id: 'd2',
        title: 'Hutang Ali',
        amount: 50,
        category: DebtCategory.risky,
        createdAt: DateTime(2026, 9, 1),
      );
      expect(DebtModel.fromJson(debt.toJson()), debt);
      expect(DebtModel.fromJson(noDate.toJson()), noDate);
    });

    test('ExpenseModel', () {
      final expense = ExpenseModel(
        id: 'e1',
        title: 'Nasi lemak',
        amount: 8.5,
        category: ExpenseCategory.makan,
        date: DateTime(2026, 9, 21, 8, 30),
      );
      expect(ExpenseModel.fromJson(expense.toJson()), expense);
    });

    test('CashflowSummary', () {
      const summary = CashflowSummary(
        totalIncome: 4000,
        totalDebt: 1300,
        totalExpense: 700,
        netRemaining: 2000,
        dailyLimit: 200,
        daysRemaining: 10,
      );
      expect(CashflowSummary.fromJson(summary.toJson()), summary);
    });
  });

  test('unknown categories fall back safely', () {
    final debt = DebtModel.fromMap({'id': 'x', 'category': 'crypto'});
    final expense = ExpenseModel.fromMap({'id': 'y', 'category': 'crypto'});
    expect(debt.category, DebtCategory.halal);
    expect(expense.category, ExpenseCategory.lainLain);
  });

  test('v1.0.0 debts migrate: paid flag becomes this month, counts always', () {
    final legacy = DebtModel.fromMap({
      'id': 'old',
      'title': 'Kereta',
      'amount': 800,
      'category': 'halal',
      'isPaid': true,
      'dueDate': null,
    });
    final thisMonth = YearMonth.of(DateTime.now());
    expect(legacy.isPaidIn(thisMonth), isTrue);
    expect(legacy.isActiveIn(const YearMonth(2020, 1)), isTrue);
  });

  test('YearMonth keys and ordering', () {
    expect(sep.key, '2026-09');
    expect(YearMonth.tryParse('2026-09'), sep);
    expect(YearMonth.tryParse('2026-13'), isNull);
    expect(const YearMonth(2027, 1).previous, const YearMonth(2026, 12));
    expect(sep.isBefore(oct), isTrue);
  });

  group('DebtModel per month', () {
    final debt = DebtModel(
      id: 'd',
      title: 'Kereta',
      amount: 800,
      category: DebtCategory.halal,
      createdAt: DateTime(2026, 9, 10),
      dueDate: DateTime(2026, 1, 31),
    );

    test('each month starts unpaid; paying one month leaves others', () {
      final paidSep = debt.togglePaidIn(sep);
      expect(paidSep.isPaidIn(sep), isTrue);
      expect(paidSep.isPaidIn(oct), isFalse);
      expect(paidSep.togglePaidIn(sep).isPaidIn(sep), isFalse);
    });

    test('a paid month keeps the amount it was paid at', () {
      final edited = debt.togglePaidIn(sep).copyWith(amount: 900);
      expect(edited.amountIn(sep), 800);
      expect(edited.amountIn(oct), 900);
    });

    test('active from its start month until the month it ended', () {
      final ended = debt.endedOn(DateTime(2026, 11, 5));
      expect(ended.isActiveIn(const YearMonth(2026, 8)), isFalse);
      expect(ended.isActiveIn(sep), isTrue);
      expect(ended.isActiveIn(oct), isTrue);
      expect(ended.isActiveIn(const YearMonth(2026, 11)), isFalse);
    });

    test('due day repeats monthly and clamps to short months', () {
      expect(debt.dueDateIn(sep), DateTime(2026, 9, 30));
      expect(debt.dueDateIn(const YearMonth(2027, 2)), DateTime(2027, 2, 28));
      expect(debt.daysUntilDue(DateTime(2026, 10, 29)), 2);
    });
  });
}
