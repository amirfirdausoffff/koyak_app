import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Ultra-minimalist dark theme.
abstract final class AppTheme {
  static const fontFamily = 'PlusJakartaSans';

  /// Jakarta's space glyph is narrow; a little extra keeps words apart.
  static const double wordSpacing = 1.5;
  static const double cardRadius = 20;
  static const double dialogRadius = 28;
  static const double fieldRadius = 14;

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.green,
      onPrimary: AppColors.background,
      secondary: AppColors.amber,
      onSecondary: AppColors.background,
      error: AppColors.amber,
      onError: AppColors.background,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerHighest: AppColors.surfaceRaised,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      fontFamily: fontFamily,
    );
    final fieldShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(fieldRadius),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.surfaceRaised,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: _fieldBorder(Colors.transparent),
        enabledBorder: _fieldBorder(Colors.transparent),
        focusedBorder: _fieldBorder(AppColors.green),
        errorBorder: _fieldBorder(AppColors.amber),
        focusedErrorBorder: _fieldBorder(AppColors.amber),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: AppColors.background,
          minimumSize: const Size(64, 50),
          shape: fieldShape,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            wordSpacing: wordSpacing,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(64, 50),
          side: const BorderSide(color: AppColors.border),
          shape: fieldShape,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            wordSpacing: wordSpacing,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.green,
          shape: fieldShape,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          selectedForegroundColor: AppColors.green,
          selectedBackgroundColor: AppColors.green.withValues(alpha: 0.14),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.surfaceRaised,
        showCheckmark: false,
        shape: StadiumBorder(),
        side: BorderSide(color: Colors.transparent),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.background,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.green.withValues(alpha: 0.14),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppColors.textPrimary
                : AppColors.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.green
                : AppColors.textMuted,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.border,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.7),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: _dialogShape,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: _dialogShape,
        headerForegroundColor: AppColors.textPrimary,
        headerHeadlineStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
        dividerColor: AppColors.border,
        todayForegroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.background
              : AppColors.green,
        ),
        todayBorder: const BorderSide(color: AppColors.green),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.background
              : AppColors.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.green
              : AppColors.background,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : AppColors.border,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceRaised,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          wordSpacing: wordSpacing,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: fieldShape,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.green,
        linearTrackColor: AppColors.surfaceRaised,
      ),
    );
  }

  static final _dialogShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(dialogRadius),
    side: const BorderSide(color: AppColors.border),
  );

  /// Plus Jakarta Sans is wide, so sizes run a touch smaller than Material's
  /// defaults and the loose Roboto letter-spacing is removed.
  static TextTheme _textTheme(TextTheme base) {
    TextStyle? tune(
      TextStyle? style, {
      required double size,
      FontWeight? weight,
      double letterSpacing = 0,
    }) => style?.copyWith(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
    );

    return base
        .copyWith(
          headlineSmall: tune(
            base.headlineSmall,
            size: 26,
            weight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
          titleLarge: tune(
            base.titleLarge,
            size: 20,
            weight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          titleMedium: tune(
            base.titleMedium,
            size: 16,
            weight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          titleSmall: tune(base.titleSmall, size: 14, weight: FontWeight.w600),
          bodyLarge: tune(base.bodyLarge, size: 15),
          bodyMedium: tune(base.bodyMedium, size: 14),
          bodySmall: tune(base.bodySmall, size: 12),
          labelLarge: tune(base.labelLarge, size: 14, weight: FontWeight.w600),
          labelMedium: tune(
            base.labelMedium,
            size: 12,
            weight: FontWeight.w600,
          ),
          labelSmall: tune(
            base.labelSmall,
            size: 11,
            weight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        )
        .apply(
          fontFamily: fontFamily,
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        );
  }

  static OutlineInputBorder _fieldBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(fieldRadius),
    borderSide: BorderSide(color: color, width: 1.2),
  );
}
