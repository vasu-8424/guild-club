import 'package:flutter/material.dart';

/// The single type scale for ToyVerse using local font assets.
///
/// Cormorant Garamond Italic is a deliberately limited editorial accent. Do not use it
/// outside wordmark sublines, gift-note copy, empty states, or onboarding's
/// welcome line.
abstract final class AppTypography {
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.12,
    letterSpacing: -0.6,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.18,
    letterSpacing: -0.3,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.2,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 14.5,
    fontWeight: FontWeight.w500,
    height: 1.45,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    height: 1.38,
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
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.4,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
