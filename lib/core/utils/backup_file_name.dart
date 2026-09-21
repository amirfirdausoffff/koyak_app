/// Backup files are named `koyak_DDMMYY.json`, e.g. `koyak_210926.json`.
abstract final class BackupFileName {
  static const prefix = 'koyak_';
  static const extension = '.json';

  static final _pattern = RegExp(r'^koyak_(\d{2})(\d{2})(\d{2})\.json$');

  static String forDate(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '$prefix${two(date.day)}${two(date.month)}'
        '${two(date.year % 100)}$extension';
  }

  /// The date encoded in [name], or null if it isn't a Koyak backup file.
  static DateTime? parseDate(String name) {
    final match = _pattern.firstMatch(name);
    if (match == null) return null;

    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = 2000 + int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    // Reject impossible dates such as 310226 rolling over into March.
    final isValid = date.day == day && date.month == month;
    return isValid ? date : null;
  }
}
