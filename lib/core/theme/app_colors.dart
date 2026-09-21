import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF12131C);
  static const surface = Color(0xFF1E202D);
  static const surfaceRaised = Color(0xFF282B3B);
  static const border = Color(0xFF2C2F40);

  static const textPrimary = Color(0xFFF9FAFB);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF6B7280);

  /// Baki & hutang selesai.
  static const green = Color(0xFF34D399);

  /// Amaran & risiko.
  static const amber = Color(0xFFF59E0B);

  // Chart series, validated as a set for colour-blind separation and
  // contrast against [surface]. Order matters: debt → expense → remaining.
  static const seriesDebt = Color(0xFF3987E5);
  static const seriesExpense = Color(0xFFD95926);
  static const seriesRemaining = Color(0xFF199E70);
}
