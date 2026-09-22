import 'package:intl/intl.dart';

import '../constants/app_strings.dart';
import 'date_helper.dart';

/// Malay date labels. Needs `initializeDateFormatting('ms')` at startup.
abstract final class DateFormatter {
  static final _month = DateFormat.yMMMM(AppStrings.dateLocale);
  static final _short = DateFormat('d MMM', AppStrings.dateLocale);
  static final _full = DateFormat('d MMM yyyy', AppStrings.dateLocale);
  static final _weekday = DateFormat('EEEE, d MMM', AppStrings.dateLocale);
  static final _longDay = DateFormat(
    'EEEE, d MMMM yyyy',
    AppStrings.dateLocale,
  );
  static final _monthName = DateFormat.MMMM(AppStrings.dateLocale);
  static final _monthShort = DateFormat.MMM(AppStrings.dateLocale);
  static final _monthYearShort = DateFormat('MMM yyyy', AppStrings.dateLocale);
  static final _time = DateFormat('h:mm a', AppStrings.dateLocale);
  static final _stamp = DateFormat('dd/MM/yyyy, hh:mm a', 'en_US');

  /// `September 2026`
  static String month(DateTime date) => _month.format(date);

  /// `Ogos`
  static String monthName(DateTime date) => _monthName.format(date);

  /// `Okt`
  static String monthShort(DateTime date) => _monthShort.format(date);

  /// `Dis 2027`
  static String monthYearShort(DateTime date) => _monthYearShort.format(date);

  /// `Isnin, 21 September 2026`
  static String longDay(DateTime date) => _longDay.format(date);

  /// `5 Okt`
  static String short(DateTime date) => _short.format(date);

  /// `5 Okt 2026`
  static String full(DateTime date) => _full.format(date);

  /// `3:45 PTG`
  static String time(DateTime date) => _time.format(date);

  /// `21/09/2026, 12:00 AM`
  static String stamp(DateTime date) => _stamp.format(date);

  /// `Hari Ini`, `Semalam`, or `Isnin, 14 Sep`.
  static String relativeDay(DateTime date, DateTime now) =>
      switch (DateHelper.daysBetween(date, now)) {
        0 => 'Hari Ini',
        1 => 'Semalam',
        _ => _weekday.format(date),
      };
}
