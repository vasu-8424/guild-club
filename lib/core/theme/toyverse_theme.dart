import 'package:flutter/material.dart';
import 'app_typography.dart';

/// Central Design System & Color Tokens for Guild Club.
/// Featuring a bold, confident Heraldic Crest palette (Crest Red, Deep Navy Blue, and Pure White).
class ToyVerseTheme {
  // 1. Heraldic Crest Master Palette
  static const Color primaryRed = Color(0xFFB91C1C); // Deep desaturated crest red
  static const Color primaryRedLight = Color(0xFFDC2626); // Accent crimson red
  static const Color primaryRedDark = Color(0xFF881337); // Deep burgundy red
  
  static const Color primaryBlue = Color(0xFF0F2B5C); // Deep navy-leaning blue
  static const Color primaryRoyalBlue = Color(0xFF1E3A8A); // Royal navy blue
  static const Color primaryNavy = Color(0xFF0F172A); // Obsidian midnight navy
  static const Color primaryBlueLight = Color(0xFF2563EB); // Vibrant cobalt blue

  // Re-aliased tokens for legacy compatibility so all screens automatically switch to Red/Blue
  static const Color primaryPurple = primaryRed;
  static const Color primaryElectricPurple = primaryBlueLight;
  static const Color primaryOrange = primaryRedLight;
  static const Color primarySkyBlue = Color(0xFF0EA5E9);
  static const Color primaryYellow = Color(0xFFEAB308);
  static const Color primaryMintGreen = Color(0xFF10B981);
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color accentCoral = primaryRedLight;
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentPink = Color(0xFFE11D48);

  // 2. Pure White & Off-White Studio Canvas Surfaces
  static const Color bgWarmWhite = Color(0xFFFAF9FB);
  static const Color bgLightGray = Color(0xFFF1F5F9);
  static const Color bgLightBlue = Color(0xFFF0F4F8);
  static const Color bgSurfaceCard = Color(0xFFFFFFFF);
  static const Color bgDarkObsidian = Color(0xFF070B12);

  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);

  // Corner Radius Tokens
  static const double radiusButton = 12.0;
  static const double radiusSmallCard = 14.0;
  static const double radiusProductCard = 18.0;
  static const double radiusNavigation = 20.0;
  static const double radiusHeroCard = 24.0;

  // 3. Heraldic Crest Master Gradients
  static const LinearGradient royalNavyGradient = LinearGradient(
    colors: [primaryNavy, primaryRoyalBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient electricPurpleGradient = LinearGradient(
    colors: [primaryRedDark, primaryRed],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient heraldicCrestGradient = LinearGradient(
    colors: [primaryRed, primaryRoyalBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient coralGlowGradient = LinearGradient(
    colors: [primaryRedLight, primaryRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeYellowGradient = LinearGradient(
    colors: [primaryRed, primaryRedLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [primaryRedDark, primaryRoyalBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient luxuryDarkGradient = LinearGradient(
    colors: [Color(0xFF070B12), Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient subtleGlassBorder = LinearGradient(
    colors: [
      Color(0x55FFFFFF),
      Color(0x1F64748B),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 4. Multi-layered Ambient & Red/Blue Soft Shadows
  static List<BoxShadow> subtleShadow({double opacity = 0.05, double blur = 16, Offset offset = const Offset(0, 4)}) {
    return [
      BoxShadow(
        color: primaryNavy.withValues(alpha: opacity),
        blurRadius: blur,
        spreadRadius: 0,
        offset: offset,
      ),
    ];
  }

  static List<BoxShadow> premiumShadow({double blur = 20, Offset offset = const Offset(0, 6)}) {
    return [
      BoxShadow(
        color: primaryNavy.withValues(alpha: 0.06),
        blurRadius: blur,
        spreadRadius: -2,
        offset: offset,
      ),
      BoxShadow(
        color: primaryRed.withValues(alpha: 0.04),
        blurRadius: 10,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static List<BoxShadow> glowShadow(Color color, {double opacity = 0.28, double blur = 20}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blur,
        spreadRadius: 0,
        offset: const Offset(0, 6),
      ),
    ];
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgWarmWhite,
      colorScheme: const ColorScheme.light(
        primary: primaryRed,
        secondary: primaryRoyalBlue,
        surface: bgWarmWhite,
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: textDark),
        displayMedium: AppTypography.displayMedium.copyWith(color: textDark),
        titleLarge: AppTypography.displayMedium.copyWith(
          fontSize: 20,
          color: textDark,
        ),
        titleMedium: AppTypography.bodyLarge.copyWith(
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: textDark),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: textMuted),
        labelLarge: AppTypography.bodyLarge.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: bgSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusProductCard),
        ),
      ),
    );
  }
}
