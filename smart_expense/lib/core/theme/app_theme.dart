import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors (Electric Indigo & Fintech Accents)
  static const Color primary = Color(0xFF4648D4);
  static const Color primaryDark = Color(0xFF6366F1);
  static const Color primaryActive = Color(0xFF2F2EBE);
  static const Color primaryContainer = Color(0xFF6063EE);
  static const Color primaryFixed = Color(0xFFE1E0FF);

  static const Color secondary = Color(0xFF006C49);
  static const Color secondaryDark = Color(0xFF10B981);
  static const Color secondaryContainer = Color(0xFFECFDF5);
  static const Color secondaryFixed = Color(0xFF6CF8BB);

  static const Color error = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFF87171);
  static const Color errorContainer = Color(0xFFFEF2F2);
  static const Color tertiary = Color(0xFFB61722);
  static const Color tertiaryContainer = Color(0xFFFFDAD6);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color warningContainer = Color(0xFFFFFBEB);

  // --- Neumorphic Light Palette ---
  static const Color lightCanvas = Color(0xFFE6ECF5); // Soft slate off-white
  static const Color lightSurface = Color(0xFFEBF1FA); // Elevated soft surface
  static const Color lightInset = Color(0xFFDFE5EE); // Sunken surface
  static const Color lightShadowTop = Color(0xFFFFFFFF); // White highlight
  static const Color lightShadowBottom = Color(0xFFA3B1C6); // Dark drop shadow

  // --- Neumorphic Dark Palette ---
  static const Color darkCanvas = Color(0xFF1B1E28); // Deep matte charcoal canvas
  static const Color darkSurface = Color(0xFF232734); // Elevated soft dark surface
  static const Color darkInset = Color(0xFF161922); // Sunken dark surface
  static const Color darkShadowTop = Color(0xFF2D3346); // Subtle top-left highlight
  static const Color darkShadowBottom = Color(0xFF10121A); // Deep velvety drop shadow

  // Legacy compatibility constants
  static const Color canvas = lightCanvas;
  static const Color surface = lightSurface;
  static const Color surfaceContainerLow = Color(0xFFF0F4FA);
  static const Color surfaceContainer = Color(0xFFE6ECF5);
  static const Color surfaceContainerHigh = Color(0xFFDCE3ED);
  static const Color surfaceContainerHighest = Color(0xFFD2DCE8);
  static const Color border = Color(0xFFD5DFEC);
  static const Color outline = Color(0xFF767586);
  static const Color outlineVariant = Color(0xFFC7C4D7);

  // Typography Colors
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;
  static const Color textMuted = lightTextMuted;

  // --- Dynamic Color & Shadow Helpers ---
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color getCanvas(BuildContext context) {
    return isDark(context) ? darkCanvas : lightCanvas;
  }

  static Color getSurface(BuildContext context) {
    return isDark(context) ? darkSurface : lightSurface;
  }

  static Color getInset(BuildContext context) {
    return isDark(context) ? darkInset : lightInset;
  }

  static Color getTextPrimary(BuildContext context) {
    return isDark(context) ? darkTextPrimary : lightTextPrimary;
  }

  static Color getTextSecondary(BuildContext context) {
    return isDark(context) ? darkTextSecondary : lightTextSecondary;
  }

  static Color getTextMuted(BuildContext context) {
    return isDark(context) ? darkTextMuted : lightTextMuted;
  }

  static Color getPrimary(BuildContext context) {
    return isDark(context) ? primaryDark : primary;
  }

  static Color getSecondary(BuildContext context) {
    return isDark(context) ? secondaryDark : secondary;
  }

  static Color getError(BuildContext context) {
    return isDark(context) ? errorDark : error;
  }

  /// Neumorphic Extruded Dual BoxShadow
  static List<BoxShadow> neuElevation(
    BuildContext context, {
    double depth = 4.0,
    double blur = 8.0,
  }) {
    final dark = isDark(context);
    final topColor = dark
        ? darkShadowTop.withValues(alpha: 0.65)
        : lightShadowTop.withValues(alpha: 0.95);
    final bottomColor = dark
        ? darkShadowBottom.withValues(alpha: 0.85)
        : lightShadowBottom.withValues(alpha: 0.55);

    return [
      BoxShadow(
        color: topColor,
        offset: Offset(-depth, -depth),
        blurRadius: blur,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: bottomColor,
        offset: Offset(depth, depth),
        blurRadius: blur,
        spreadRadius: 0,
      ),
    ];
  }

  /// Neumorphic Subtle Glow / Focus Shadow
  static List<BoxShadow> neuGlow(Color color, {double blur = 12.0}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: 0.35),
        offset: const Offset(0, 4),
        blurRadius: blur,
        spreadRadius: 1,
      ),
    ];
  }

  // --- Light ThemeData ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightCanvas,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        error: error,
        surface: lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onSurface: lightTextPrimary,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: lightCanvas,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: lightTextPrimary),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: lightTextPrimary,
          fontFamily: 'Inter',
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
    );
  }

  // --- Dark ThemeData ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkCanvas,
      primaryColor: primaryDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        secondary: secondaryDark,
        error: errorDark,
        surface: darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
        onSurface: darkTextPrimary,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCanvas,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkTextPrimary),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: darkTextPrimary,
          fontFamily: 'Inter',
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
