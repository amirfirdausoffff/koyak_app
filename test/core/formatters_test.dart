import 'package:flutter_test/flutter_test.dart';
import 'package:koyak/core/utils/currency_formatter.dart';
import 'package:koyak/core/utils/date_helper.dart';
import 'package:koyak/core/utils/percent_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats Ringgit with grouping and 2 decimals', () {
      expect(1250.asRinggit, 'RM 1,250.00');
      expect(0.5.asRinggit, 'RM 0.50');
      expect(1234567.891.asRinggit, 'RM 1,234,567.89');
    });

    test('puts the sign before RM and never shows -RM 0.00', () {
      expect((-50.5).asRinggit, '-RM 50.50');
      expect((-0.004).asRinggit, 'RM 0.00');
    });

    test('parses user input', () {
      expect(CurrencyFormatter.parse('12.5'), 12.5);
      expect(CurrencyFormatter.parse('1,250.00'), 1250);
      expect(CurrencyFormatter.parse('abc'), isNull);
    });
  });

  test('PercentFormatter rounds and flags tiny shares', () {
    expect(PercentFormatter.format(42.4), '42%');
    expect(PercentFormatter.format(0.3), '<1%');
    expect(PercentFormatter.format(0), '0%');
  });

  group('DateHelper', () {
    test('days remaining counts today', () {
      expect(DateHelper.daysRemainingInMonth(DateTime(2026, 9, 21)), 10);
      expect(DateHelper.daysRemainingInMonth(DateTime(2026, 9, 30)), 1);
      expect(DateHelper.daysRemainingInMonth(DateTime(2028, 2, 1)), 29);
    });

    test('addMonths clamps to month length', () {
      expect(
        DateHelper.addMonths(DateTime(2026, 1, 31), 1),
        DateTime(2026, 2, 28),
      );
      expect(
        DateHelper.addMonths(DateTime(2026, 12, 5), 1),
        DateTime(2027, 1, 5),
      );
    });
  });
}
