import 'package:flutter/material.dart';

/// Design tokens for the Card Scan app's modern glassmorphism theme.
/// These constants ensure consistency across all UI components.

class DesignTokens {
  // Colors
  static const Color primaryColor = Color(0xFF6366F1); // Indigo
  static const Color surfaceColor = Color(0xFFF8F9FA); // Light surface
  static const Color glassOpacity = Color(0xB3FFFFFF); // Semi-transparent white

  // Border Radius
  static const double borderRadiusSmall = 12.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 20.0;
  static const double borderRadiusExtraLarge = 24.0;

  // Blur
  static const double blurSigma = 10.0;

  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x1A000000), // Black with 10% opacity
      blurRadius: 20.0,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0D6366F1), // Primary with 5% opacity
      blurRadius: 40.0,
      offset: Offset(0, 16),
    ),
  ];

  static const List<BoxShadow> avatarShadow = [
    BoxShadow(
      color: Color(0x4D6366F1), // Primary with 30% opacity
      blurRadius: 12.0,
      offset: Offset(0, 4),
    ),
  ];

  // Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      surfaceColor,
      Color(0x0D6366F1), // Primary container with 5% opacity
    ],
  );

  static const LinearGradient avatarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryColor,
      Color(0xFF8B5CF6), // Purple accent
    ],
  );

  // Animation Durations
  static const Duration animationDurationFast = Duration(milliseconds: 150);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationSlow = Duration(milliseconds: 400);

  // Spacing
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingLarge = 16.0;
  static const double spacingExtraLarge = 20.0;
  static const double spacingXXLarge = 24.0;

  // Padding
  static const EdgeInsets paddingSmall = EdgeInsets.all(spacingSmall);
  static const EdgeInsets paddingMedium = EdgeInsets.all(spacingMedium);
  static const EdgeInsets paddingLarge = EdgeInsets.all(spacingLarge);
  static const EdgeInsets paddingExtraLarge = EdgeInsets.all(spacingExtraLarge);

  // Typography Weights
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;

  // Glassmorphism Container
  static BoxDecoration glassDecoration(BuildContext context,
      {bool selected = false}) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: (selected
              ? theme.colorScheme.primaryContainer
              : theme.cardTheme.color ?? theme.colorScheme.surface)
          .withOpacity(0.7),
      borderRadius: BorderRadius.circular(borderRadiusExtraLarge),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
      boxShadow: cardShadow,
    );
  }

  // Common Widget Styles
  static ButtonStyle elevatedButtonStyle(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(
          horizontal: spacingExtraLarge, vertical: spacingLarge),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusLarge),
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
    );
  }

  static ButtonStyle outlinedButtonStyle(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton.styleFrom(
      foregroundColor: theme.colorScheme.primary,
      padding: const EdgeInsets.symmetric(
          horizontal: spacingExtraLarge, vertical: spacingLarge),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusLarge),
      ),
      side: BorderSide(
        color: theme.colorScheme.primary.withOpacity(0.5),
        width: 1.5,
      ),
    );
  }
}
