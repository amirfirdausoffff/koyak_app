abstract final class PercentFormatter {
  /// `42.4` → `42%`; tiny non-zero shares show as `<1%` instead of `0%`.
  static String format(double percentage) {
    if (percentage > 0 && percentage < 1) return '<1%';
    return '${percentage.round()}%';
  }
}
