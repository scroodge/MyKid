import 'package:flutter/material.dart';

/// MyKid brand colors. Single source of truth; no raw hex elsewhere in brand layer.
abstract final class MyKidColors {
  MyKidColors._();

  // --- Core palette ---
  /// Primary background. Warm Sand #F4EFEA.
  static const Color warmSand = Color(0xFFF4EFEA);

  /// Primary text. Soft Charcoal #2E2E2E.
  static const Color softCharcoal = Color(0xFF2E2E2E);

  /// Accent primary. Dusty Blue #7A9BBE.
  static const Color dustyBlue = Color(0xFF7A9BBE);

  /// Accent secondary. Soft Sage #9FB8A0.
  static const Color softSage = Color(0xFF9FB8A0);

  /// Emotional accent (e.g. Today, Important). Muted Coral #E38B7A.
  static const Color mutedCoral = Color(0xFFE38B7A);

  /// Divider / outline. Mist Gray #D9D4CF.
  static const Color mistGray = Color(0xFFD9D4CF);

  // --- Surface variants (subtle; photos are hero) ---
  /// Slightly dimmer than surface for cards/elevated areas.
  static const Color surfaceDim = Color(0xFFEDE8E3);

  /// Lowest surface container for cards.
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  /// Low surface container.
  static const Color surfaceContainerLow = Color(0xFFF8F4F0);

  /// Default surface container.
  static const Color surfaceContainer = Color(0xFFF0EBE6);

  /// High surface container.
  static const Color surfaceContainerHigh = Color(0xFFEAE5E0);

  /// Highest surface container.
  static const Color surfaceContainerHighest = Color(0xFFE5DFDA);

  // --- Dark theme (same hues, darkened) ---
  static const Color warmSandDark = Color(0xFF1C1A18);
  static const Color softCharcoalDark = Color(0xFFE6E4E2);
  static const Color dustyBlueDark = Color(0xFF9BB4D6);
  static const Color softSageDark = Color(0xFFA8C0A8);
  static const Color mutedCoralDark = Color(0xFFE8A99C);
  static const Color mistGrayDark = Color(0xFF4A4744);
  static const Color surfaceDimDark = Color(0xFF252320);
  static const Color surfaceContainerLowestDark = Color(0xFF1C1A18);
  static const Color surfaceContainerLowDark = Color(0xFF2A2825);
  static const Color surfaceContainerDark = Color(0xFF2E2C29);
  static const Color surfaceContainerHighDark = Color(0xFF393633);
  static const Color surfaceContainerHighestDark = Color(0xFF44413D);
}
