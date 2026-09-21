import 'package:intl/intl.dart';

/// Every money value in the app is Ringgit Malaysia, e.g. `RM 1,250.00`.
abstract final class CurrencyFormatter {
  static const symbol = 'RM';

  // Fixed locale so grouping is always "1,250.00" regardless of phone setting.
  static final NumberFormat _number = NumberFormat('#,##0.00', 'en_US');

  /// `1250` → `RM 1,250.00`, `-50.5` → `-RM 50.50`.
  static String format(num amount) {
    final cents = _toCents(amount);
    final sign = cents < 0 ? '-' : '';
    return '$sign$symbol ${_number.format(cents.abs() / 100)}';
  }

  /// Unsigned amount without the symbol, e.g. `1,250.00`.
  static String formatNumber(num amount) =>
      _number.format(_toCents(amount).abs() / 100);

  /// Parses user input such as `12.5`; returns null when invalid.
  static double? parse(String input) =>
      double.tryParse(input.replaceAll(',', '').trim());

  static int _toCents(num amount) => (amount * 100).round();
}

extension RinggitFormat on num {
  String get asRinggit => CurrencyFormatter.format(this);
}
