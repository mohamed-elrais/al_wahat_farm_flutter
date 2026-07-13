import 'package:al_wahat_farm_flutter/app/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Platform Arabic-capable fonts to fall back to for glyphs the bundled Latin
/// fonts (Inter / Libre Baskerville) do not cover. Flutter resolves these
/// against the device's installed fonts, so Arabic renders natively on iOS and
/// Android without bundling or downloading a font.
const List<String> _arabicFallback = <String>[
  'Geeza Pro',
  'Noto Sans Arabic',
  'Noto Kufi Arabic',
  'Arial',
];

abstract final class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.green,
      secondary: AppColors.orange,
      surface: AppColors.card,
      error: AppColors.issue,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.ink,
      onError: Colors.white,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.paper,
      fontFamily: 'Inter',
    );
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge: _serif(48, FontWeight.w700, height: 1.02),
        displayMedium: _serif(38, FontWeight.w700, height: 1.04),
        headlineLarge: _serif(30, FontWeight.w700),
        headlineMedium: _serif(24, FontWeight.w700),
        titleLarge: _serif(20, FontWeight.w700),
        bodyLarge: const TextStyle(
          color: AppColors.ink,
          fontFamily: 'Inter',
          fontFamilyFallback: _arabicFallback,
          fontSize: 16,
          height: 1.55,
        ),
        bodyMedium: const TextStyle(
          color: AppColors.muted,
          fontFamily: 'Inter',
          fontFamilyFallback: _arabicFallback,
          fontSize: 14,
          height: 1.5,
        ),
        labelLarge: const TextStyle(
          fontFamily: 'Inter',
          fontFamilyFallback: _arabicFallback,
          fontWeight: FontWeight.w800,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontFamilyFallback: _arabicFallback,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: _inputBorder(AppColors.line),
        enabledBorder: _inputBorder(AppColors.line),
        focusedBorder: _inputBorder(AppColors.green, width: 1.5),
        errorBorder: _inputBorder(AppColors.issue),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(color: Colors.white, fontFamily: 'Inter'),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card,
        selectedColor: AppColors.green,
        checkmarkColor: Colors.white,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(99),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  static TextStyle _serif(double size, FontWeight weight, {double? height}) =>
      TextStyle(
        color: AppColors.ink,
        fontFamily: 'LibreBaskerville',
        fontFamilyFallback: const <String>[
          'Georgia',
          ..._arabicFallback,
          'serif',
        ],
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: -0.5,
      );

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.control),
        borderSide: BorderSide(color: color, width: width),
      );
}
