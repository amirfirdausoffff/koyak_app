import 'package:flutter/foundation.dart';

import '../core/utils/date_helper.dart';

/// A calendar month — the unit every Koyak total is counted in.
@immutable
class YearMonth implements Comparable<YearMonth> {
  const YearMonth(this.year, this.month);

  factory YearMonth.of(DateTime date) => YearMonth(date.year, date.month);

  /// Parses a [key] such as `2026-09`.
  static YearMonth? tryParse(String key) {
    final match = _keyPattern.firstMatch(key);
    if (match == null) return null;
    final month = int.parse(match.group(2)!);
    if (month < 1 || month > 12) return null;
    return YearMonth(int.parse(match.group(1)!), month);
  }

  static final _keyPattern = RegExp(r'^(\d{4})-(\d{2})$');

  final int year;
  final int month;

  /// Storage key, e.g. `2026-09`.
  String get key => '$year-${month.toString().padLeft(2, '0')}';

  int get dayCount => DateHelper.daysInMonth(year, month);

  /// Midnight on the 1st.
  DateTime get start => DateTime(year, month);

  YearMonth get previous => YearMonth.of(DateTime(year, month - 1));

  YearMonth get next => YearMonth.of(DateTime(year, month + 1));

  bool contains(DateTime date) => date.year == year && date.month == month;

  bool isBefore(YearMonth other) => compareTo(other) < 0;

  @override
  int compareTo(YearMonth other) =>
      (year * 12 + month) - (other.year * 12 + other.month);

  @override
  bool operator ==(Object other) =>
      other is YearMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => key;
}
