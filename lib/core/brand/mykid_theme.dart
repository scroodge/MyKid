import 'package:flutter/material.dart';

import 'mykid_colors.dart';
import 'mykid_spacing.dart';
import 'mykid_typography.dart';

/// MyKid Material 3 theme. Light (default) and dark.
abstract final class MyKidTheme {
  MyKidTheme._();

  static ColorScheme get _lightColorScheme {
    return ColorScheme(
      brightness: Brightness.light,
      primary: MyKidColors.dustyBlue,
      onPrimary: Colors.white,
      primaryContainer: MyKidColors.dustyBlue.withValues(alpha: 0.2),
      onPrimaryContainer: MyKidColors.softCharcoal,
      secondary: MyKidColors.softSage,
      onSecondary: MyKidColors.softCharcoal,
      secondaryContainer: MyKidColors.softSage.withValues(alpha: 0.3),
      onSecondaryContainer: MyKidColors.softCharcoal,
      tertiary: MyKidColors.mutedCoral,
      onTertiary: Colors.white,
      tertiaryContainer: MyKidColors.mutedCoral.withValues(alpha: 0.25),
      onTertiaryContainer: MyKidColors.softCharcoal,
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
      surface: MyKidColors.warmSand,
      onSurface: MyKidColors.softCharcoal,
      surfaceDim: MyKidColors.surfaceDim,
      surfaceBright: MyKidColors.surfaceContainerLowest,
      surfaceContainerLowest: MyKidColors.surfaceContainerLowest,
      surfaceContainerLow: MyKidColors.surfaceContainerLow,
      surfaceContainer: MyKidColors.surfaceContainer,
      surfaceContainerHigh: MyKidColors.surfaceContainerHigh,
      surfaceContainerHighest: MyKidColors.surfaceContainerHighest,
      onSurfaceVariant: MyKidColors.softCharcoal.withValues(alpha: 0.8),
      outline: MyKidColors.mistGray,
      outlineVariant: MyKidColors.mistGray.withValues(alpha: 0.6),
      shadow: Colors.black26,
      scrim: Colors.black54,
      inverseSurface: MyKidColors.softCharcoal,
      onInverseSurface: MyKidColors.warmSand,
      inversePrimary: MyKidColors.dustyBlue.withValues(alpha: 0.8),
      surfaceTint: MyKidColors.dustyBlue,
    );
  }

  static ColorScheme get _darkColorScheme {
    return ColorScheme(
      brightness: Brightness.dark,
      primary: MyKidColors.dustyBlueDark,
      onPrimary: MyKidColors.softCharcoal,
      primaryContainer: MyKidColors.dustyBlueDark.withValues(alpha: 0.3),
      onPrimaryContainer: MyKidColors.softCharcoalDark,
      secondary: MyKidColors.softSageDark,
      onSecondary: MyKidColors.softCharcoal,
      secondaryContainer: MyKidColors.softSageDark.withValues(alpha: 0.3),
      onSecondaryContainer: MyKidColors.softCharcoalDark,
      tertiary: MyKidColors.mutedCoralDark,
      onTertiary: MyKidColors.softCharcoal,
      tertiaryContainer: MyKidColors.mutedCoralDark.withValues(alpha: 0.25),
      onTertiaryContainer: MyKidColors.softCharcoalDark,
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
      surface: MyKidColors.warmSandDark,
      onSurface: MyKidColors.softCharcoalDark,
      surfaceDim: MyKidColors.surfaceDimDark,
      surfaceBright: MyKidColors.surfaceContainerLowDark,
      surfaceContainerLowest: MyKidColors.surfaceContainerLowestDark,
      surfaceContainerLow: MyKidColors.surfaceContainerLowDark,
      surfaceContainer: MyKidColors.surfaceContainerDark,
      surfaceContainerHigh: MyKidColors.surfaceContainerHighDark,
      surfaceContainerHighest: MyKidColors.surfaceContainerHighestDark,
      onSurfaceVariant: MyKidColors.softCharcoalDark.withValues(alpha: 0.8),
      outline: MyKidColors.mistGrayDark,
      outlineVariant: MyKidColors.mistGrayDark.withValues(alpha: 0.6),
      shadow: Colors.black,
      scrim: Colors.black87,
      inverseSurface: MyKidColors.softCharcoalDark,
      onInverseSurface: MyKidColors.warmSandDark,
      inversePrimary: MyKidColors.dustyBlueDark.withValues(alpha: 0.5),
      surfaceTint: MyKidColors.dustyBlueDark,
    );
  }

  static ThemeData get lightTheme {
    final colorScheme = _lightColorScheme;
    final textTheme = MyKidTypography.textTheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLowest,
        elevation: 0.5,
        shadowColor: colorScheme.shadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        selectedColor: MyKidColors.softSage.withValues(alpha: 0.4),
        disabledColor: colorScheme.surfaceContainerHighest,
        labelStyle: textTheme.labelLarge,
        secondaryLabelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: MyKidSpacing.sm,
          vertical: MyKidSpacing.xs,
        ),
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MyKidSpacing.md,
          vertical: MyKidSpacing.sm,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        labelStyle: textTheme.bodyLarge,
        alignLabelWithHint: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = _darkColorScheme;
    final textTheme = MyKidTypography.textTheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLowest,
        elevation: 0.5,
        shadowColor: colorScheme.shadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        selectedColor: MyKidColors.softSageDark.withValues(alpha: 0.4),
        disabledColor: colorScheme.surfaceContainerHighest,
        labelStyle: textTheme.labelLarge,
        secondaryLabelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(
          horizontal: MyKidSpacing.sm,
          vertical: MyKidSpacing.xs,
        ),
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MyKidSpacing.md,
          vertical: MyKidSpacing.sm,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        labelStyle: textTheme.bodyLarge,
        alignLabelWithHint: true,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
      ),
    );
  }
}
