import 'package:flutter/material.dart';

/// Quantum Neural Theme - Dark futuristic aesthetic inspired by the HTML design
class QuantumTheme {
  // Core colors
  static const Color deepSpace = Color(0xFF0a0e27);
  static const Color primaryBlue = Color(0xFF3b82f6);
  static const Color primaryPurple = Color(0xFF8b5cf6);
  static const Color accentPink = Color(0xFFec4899);
  static const Color successGreen = Color(0xFF10b981);
  static const Color errorRed = Color(0xFFef4444);

  // Glass morphism colors
  static const Color glassBase = Color(0x05FFFFFF);
  static const Color glassBorder = Color(0x0DFFFFFF);

  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary =
      Color(0xB3FFFFFF); // white with 0.7 opacity
  static const Color textTertiary = Color(0x66FFFFFF); // white with 0.4 opacity

  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [primaryBlue, primaryPurple, accentPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), successGreen],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Holographic gradient for scan area
  static LinearGradient holographicGradient({double opacity = 0.15}) {
    return LinearGradient(
      colors: [
        primaryBlue.withOpacity(opacity),
        primaryPurple.withOpacity(opacity),
        primaryBlue.withOpacity(opacity * 1.2),
        primaryPurple.withOpacity(opacity),
        primaryBlue.withOpacity(opacity),
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // Box shadows
  static List<BoxShadow> neuralGlow({
    Color? color,
    double blurRadius = 40,
    double spreadRadius = 0,
    double opacity = 0.4,
  }) {
    return [
      BoxShadow(
        color: (color ?? primaryBlue).withOpacity(opacity),
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
        offset: const Offset(0, 0),
      ),
    ];
  }

  static List<BoxShadow> cardShadow({double opacity = 0.4}) {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(opacity),
        blurRadius: 32,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: primaryBlue.withOpacity(0.2),
        blurRadius: 60,
        spreadRadius: 0,
      ),
    ];
  }

  // Border radius
  static BorderRadius cardRadius = BorderRadius.circular(24);
  static BorderRadius buttonRadius = BorderRadius.circular(16);
  static BorderRadius chipRadius = BorderRadius.circular(50);

  // Theme data
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: primaryPurple,
        surface: deepSpace,
        surfaceContainer: Color(0xFF1E1E1E),
        onSurface: textPrimary,
        error: errorRed,
        tertiary: accentPink,
      ),
      scaffoldBackgroundColor: deepSpace,

      // Card theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
        color: glassBase,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: buttonRadius),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          side: BorderSide(color: textPrimary.withOpacity(0.1), width: 1),
          backgroundColor: textPrimary.withOpacity(0.05),
          foregroundColor: textPrimary,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: chipRadius),
        backgroundColor: primaryBlue.withOpacity(0.15),
        labelStyle: const TextStyle(
          color: primaryBlue,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // FAB theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        elevation: 0,
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: const Color(0xFF1E1E1E).withOpacity(0.9),
        elevation: 0,
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryBlue,
      ),
    );
  }
}
