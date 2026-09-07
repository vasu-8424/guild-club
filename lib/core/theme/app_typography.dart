import 'package:flutter/material.dart';

/// The single type scale for ToyVerse using local font assets.
///
/// Cormorant Garamond Italic is a deliberately limited editorial accent. Do not use it
/// outside wordmark sublines, gift-note copy, empty states, or onboarding's
/// welcome line.
abstract final class AppTypography {
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.08,
    letterSpacing: -0.7,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Outfit',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.16,
    letterSpacing: -0.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.42,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.35,
  );

  static const TextStyle accentScript = TextStyle(
    fontFamily: 'CormorantGaramond',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontStyle: FontStyle.italic,
    height: 1.2,
    letterSpacing: 0.1,
  );

  static const TextStyle priceNumeral = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
