import 'package:flutter/material.dart';

import '../app_theme.dart';

/// Design tokens for the Card Scan app's modern glassmorphism theme.
/// These values respond to the active [ThemeData] and palette extensions,
/// keeping surfaces, accents, and radii in sync with the selected scheme.
class DesignTokens {
  const DesignTokens._();

  // Radii
  static const double borderRadiusSmall = 12.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 20.0;
  static const double borderRadiusExtraLarge = 24.0;

  static BorderRadius get radiusSmall => BorderRadius.circular(borderRadiusSmall);
  static BorderRadius get radiusMedium => BorderRadius.circular(borderRadiusMedium);
  static BorderRadius get radiusLarge => BorderRadius.circular(borderRadiusLarge);
  static BorderRadius get radiusExtraLarge => BorderRadius.circular(borderRadiusExtraLarge);
  static BorderRadius get radiusPill => BorderRadius.circular(999);
  static OutlinedBorder squircle({double radius = 28}) =>
      ContinuousRectangleBorder(borderRadius: BorderRadius.circular(radius));
  static OutlinedBorder organicCardShape({double radius = 26}) =>
      ContinuousRectangleBorder(borderRadius: BorderRadius.circular(radius));

  // Blur
  static const double blurSigma = 14.0;

  // Animation Durations
  static const Duration animationDurationFast = Duration(milliseconds: 150);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationSlow = Duration(milliseconds: 420);

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

  static LinearGradient backgroundGradient(BuildContext context) {
    final theme = Theme.of(context);
    final palettes = _palettes(context);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        theme.colorScheme.surface,
        palettes.soothingGradient.colors.first.withOpacity(0.45),
        palettes.vibrantGradient.colors.last.withOpacity(0.25),
      ],
      stops: const [0.0, 0.6, 1.0],
    );
  }

  static LinearGradient avatarGradient(BuildContext context) =>
      _palettes(context).vibrantGradient;

  static LinearGradient accentGradient(BuildContext context) =>
      _palettes(context).soothingGradient;

  static List<BoxShadow> cardShadow(BuildContext context) {
    final theme = Theme.of(context);
    final palettes = _palettes(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return [
      BoxShadow(
        color: palettes.neutral.primary.withOpacity(isDark ? 0.25 : 0.12),
        blurRadius: isDark ? 40 : 28,
        spreadRadius: 0,
        offset: const Offset(0, 18),
      ),
      BoxShadow(
        color: palettes.info.primary.withOpacity(isDark ? 0.2 : 0.1),
        blurRadius: isDark ? 60 : 42,
        offset: const Offset(0, 26),
      ),
    ];
  }

  static List<BoxShadow> avatarShadow(BuildContext context) {
    final theme = Theme.of(context);
    final palettes = _palettes(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return [
      BoxShadow(
        color: palettes.vibrantGradient.colors.last
            .withOpacity(isDark ? 0.4 : 0.28),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static BoxDecoration glassDecoration(BuildContext context,
      {bool selected = false}) {
    final theme = Theme.of(context);
    final palettes = _palettes(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final Color base = theme.colorScheme.surface.withOpacity(isDark ? 0.55 : 0.8);
    final Color focusColor = (selected
            ? palettes.success.primary
            : palettes.info.primary)
        .withOpacity(isDark ? 0.24 : 0.16);
    final Color tint = Color.alphaBlend(focusColor, base);

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(
            palettes.neutral.primary.withOpacity(isDark ? 0.16 : 0.08),
            base,
          ),
          tint,
          Color.alphaBlend(
            palettes.warning.primary.withOpacity(isDark ? 0.18 : 0.1),
            base,
          ),
        ],
      ),
      borderRadius: radiusExtraLarge,
      border: Border.all(
        color: palettes.neutral.primaryContainer.withOpacity(isDark ? 0.4 : 0.28),
        width: 1.2,
      ),
      boxShadow: cardShadow(context),
    );
  }

  static ButtonStyle elevatedButtonStyle(BuildContext context) {
    final theme = Theme.of(context);
    final palettes = _palettes(context);
    return ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(
          horizontal: spacingExtraLarge, vertical: spacingLarge),
      textStyle:
          theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      shape: squircle(radius: borderRadiusLarge),
      shadowColor: palettes.info.primary.withOpacity(0.2),
    );
  }

  static ButtonStyle outlinedButtonStyle(BuildContext context) {
    final theme = Theme.of(context);
    final palettes = _palettes(context);
    return OutlinedButton.styleFrom(
      foregroundColor: theme.colorScheme.primary,
      padding: const EdgeInsets.symmetric(
          horizontal: spacingExtraLarge, vertical: spacingLarge),
      textStyle:
          theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      shape: squircle(radius: borderRadiusLarge),
      side: BorderSide(
        color: palettes.neutral.primary.withOpacity(0.4),
        width: 1.5,
      ),
    );
  }

  static AppPalettes _palettes(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppPalettes>() ??
        AppPalettes.fallback(theme.colorScheme);
  }
}
