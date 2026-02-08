import 'package:flutter/material.dart';

/// MyKid typography. Headings: Manrope (600–700). Body/UI: Inter (400–600).
/// Fonts are declared in pubspec.yaml; no runtime fetching.
abstract final class MyKidTypography {
  MyKidTypography._();

  static const String _manrope = 'Manrope';
  static const String _inter = 'Inter';

  static TextTheme get textTheme {
    return TextTheme(
      // Display — Manrope, bold
      displayLarge: const TextStyle(
        fontFamily: _manrope,
        fontWeight: FontWeight.w700,
        fontSize: 57,
        letterSpacing: -0.25,
        height: 1.12,
      ),
      displayMedium: const TextStyle(
        fontFamily: _manrope,
        fontWeight: FontWeight.w700,
        fontSize: 45,
        height: 1.16,
      ),
      displaySmall: const TextStyle(
        fontFamily: _manrope,
        fontWeight: FontWeight.w600,
        fontSize: 36,
        height: 1.22,
      ),
      // Headline — Manrope
      headlineLarge: const TextStyle(
        fontFamily: _manrope,
        fontWeight: FontWeight.w600,
        fontSize: 32,
        height: 1.25,
      ),
      headlineMedium: const TextStyle(
        fontFamily: _manrope,
        fontWeight: FontWeight.w600,
        fontSize: 28,
        height: 1.29,
      ),
      headlineSmall: const TextStyle(
        fontFamily: _manrope,
        fontWeight: FontWeight.w600,
        fontSize: 24,
        height: 1.33,
      ),
      // Title — Manrope for larger, Inter for smaller
      titleLarge: const TextStyle(
        fontFamily: _manrope,
        fontWeight: FontWeight.w600,
        fontSize: 22,
        height: 1.27,
      ),
      titleMedium: const TextStyle(
        fontFamily: _inter,
        fontWeight: FontWeight.w600,
        fontSize: 16,
        letterSpacing: 0.15,
        height: 1.50,
      ),
      titleSmall: const TextStyle(
        fontFamily: _inter,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      // Body — Inter
      bodyLarge: const TextStyle(
        fontFamily: _inter,
        fontWeight: FontWeight.w400,
        fontSize: 16,
        letterSpacing: 0.5,
        height: 1.50,
      ),
      bodyMedium: const TextStyle(
        fontFamily: _inter,
        fontWeight: FontWeight.w400,
        fontSize: 14,
        letterSpacing: 0.25,
        height: 1.43,
      ),
      bodySmall: const TextStyle(
        fontFamily: _inter,
        fontWeight: FontWeight.w400,
        fontSize: 12,
        letterSpacing: 0.4,
        height: 1.33,
      ),
      // Label — Inter
      labelLarge: const TextStyle(
        fontFamily: _inter,
        fontWeight: FontWeight.w500,
        fontSize: 14,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      labelMedium: const TextStyle(
        fontFamily: _inter,
        fontWeight: FontWeight.w500,
        fontSize: 12,
        letterSpacing: 0.5,
        height: 1.33,
      ),
      labelSmall: const TextStyle(
        fontFamily: _inter,
        fontWeight: FontWeight.w500,
        fontSize: 11,
        letterSpacing: 0.5,
        height: 1.45,
      ),
    );
  }
}
