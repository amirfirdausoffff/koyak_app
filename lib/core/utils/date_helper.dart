import 'dart:math' as math;

/// Calendar maths used by the cashflow rules.
abstract final class DateHelper {
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// Days left in [now]'s month, today included (30 Sep → 1).
  static int daysRemainingInMonth(DateTime now) =>
      daysInMonth(now.year, now.month) - now.day + 1;

  /// Whole calendar days from [from] to [to] (negative when [to] is earlier).
  static int daysBetween(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

  /// Adds [months], clamping the day to the target month (31 Jan + 1 → 28 Feb).
  static DateTime addMonths(DateTime date, int months) {
    final target = DateTime(date.year, date.month + months);
    final day = math.min(date.day, daysInMonth(target.year, target.month));
    return DateTime(target.year, target.month, day);
  }
}
