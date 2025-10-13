import 'package:flutter/material.dart';

@immutable
class AppPalettes extends ThemeExtension<AppPalettes> {
  const AppPalettes({
    required this.success,
    required this.warning,
    required this.info,
    required this.neutral,
    required this.vibrantGradient,
    required this.soothingGradient,
    required this.glassHighlight,
  });

  final ColorScheme success;
  final ColorScheme warning;
  final ColorScheme info;
  final ColorScheme neutral;
  final LinearGradient vibrantGradient;
  final LinearGradient soothingGradient;
  final LinearGradient glassHighlight;

  static AppPalettes fromSeeds({
    required ColorScheme base,
    required ColorScheme success,
    required ColorScheme warning,
    required ColorScheme info,
    required ColorScheme neutral,
  }) {
    final LinearGradient vibrant = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        base.primary,
        info.primary,
        success.primary,
      ],
      stops: const [0.0, 0.45, 1.0],
    );

    final LinearGradient soothing = LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [
        neutral.primaryContainer,
        warning.primary,
        base.secondaryContainer,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final LinearGradient glass = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        base.surface.withOpacity(0.65),
        Color.alphaBlend(info.primary.withOpacity(0.08), base.surface),
        Color.alphaBlend(success.primary.withOpacity(0.12), base.surface),
      ],
      stops: const [0.0, 0.45, 1.0],
    );

    return AppPalettes(
      success: success,
      warning: warning,
      info: info,
      neutral: neutral,
      vibrantGradient: vibrant,
      soothingGradient: soothing,
      glassHighlight: glass,
    );
  }

  AppPalettes copyWith({
    ColorScheme? success,
    ColorScheme? warning,
    ColorScheme? info,
    ColorScheme? neutral,
    LinearGradient? vibrantGradient,
    LinearGradient? soothingGradient,
    LinearGradient? glassHighlight,
  }) {
    return AppPalettes(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      neutral: neutral ?? this.neutral,
      vibrantGradient: vibrantGradient ?? this.vibrantGradient,
      soothingGradient: soothingGradient ?? this.soothingGradient,
      glassHighlight: glassHighlight ?? this.glassHighlight,
    );
  }

  @override
  ThemeExtension<AppPalettes> lerp(AppPalettes? other, double t) {
    if (other == null) {
      return this;
    }

    return AppPalettes(
      success: ColorScheme.lerp(success, other.success, t) ?? success,
      warning: ColorScheme.lerp(warning, other.warning, t) ?? warning,
      info: ColorScheme.lerp(info, other.info, t) ?? info,
      neutral: ColorScheme.lerp(neutral, other.neutral, t) ?? neutral,
      vibrantGradient:
          LinearGradient.lerp(vibrantGradient, other.vibrantGradient, t)!,
      soothingGradient:
          LinearGradient.lerp(soothingGradient, other.soothingGradient, t)!,
      glassHighlight:
          LinearGradient.lerp(glassHighlight, other.glassHighlight, t)!,
    );
  }

  static AppPalettes fallback(ColorScheme scheme) {
    final ColorScheme accent(Color seed) => ColorScheme.fromSeed(
          seedColor: seed,
          brightness: scheme.brightness,
        );

    return AppPalettes.fromSeeds(
      base: scheme,
      success: accent(const Color(0xFF22C55E)),
      warning: accent(const Color(0xFFF59E0B)),
      info: accent(const Color(0xFF0EA5E9)),
      neutral: accent(const Color(0xFF64748B)),
    );
  }
}

class AppTheme {
  static const Color _brandSeed = Color(0xFF6366F1);
  static const Color _successSeed = Color(0xFF22C55E);
  static const Color _warningSeed = Color(0xFFF59E0B);
  static const Color _infoSeed = Color(0xFF0EA5E9);
  static const Color _neutralSeed = Color(0xFF64748B);

  static ThemeData light({
    ColorScheme? dynamicScheme,
    ColorScheme? dynamicSuccess,
    ColorScheme? dynamicWarning,
    ColorScheme? dynamicInfo,
    ColorScheme? dynamicNeutral,
  }) {
    return _buildTheme(
      brightness: Brightness.light,
      dynamicScheme: dynamicScheme,
      dynamicSuccess: dynamicSuccess,
      dynamicWarning: dynamicWarning,
      dynamicInfo: dynamicInfo,
      dynamicNeutral: dynamicNeutral,
    );
  }

  static ThemeData dark({
    ColorScheme? dynamicScheme,
    ColorScheme? dynamicSuccess,
    ColorScheme? dynamicWarning,
    ColorScheme? dynamicInfo,
    ColorScheme? dynamicNeutral,
  }) {
    return _buildTheme(
      brightness: Brightness.dark,
      dynamicScheme: dynamicScheme,
      dynamicSuccess: dynamicSuccess,
      dynamicWarning: dynamicWarning,
      dynamicInfo: dynamicInfo,
      dynamicNeutral: dynamicNeutral,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    ColorScheme? dynamicScheme,
    ColorScheme? dynamicSuccess,
    ColorScheme? dynamicWarning,
    ColorScheme? dynamicInfo,
    ColorScheme? dynamicNeutral,
  }) {
    final ColorScheme baseScheme =
        dynamicScheme ?? ColorScheme.fromSeed(
          seedColor: _brandSeed,
          brightness: brightness,
        );

    final ColorScheme successScheme =
        dynamicSuccess ?? ColorScheme.fromSeed(
          seedColor: _successSeed,
          brightness: brightness,
        );

    final ColorScheme warningScheme =
        dynamicWarning ?? ColorScheme.fromSeed(
          seedColor: _warningSeed,
          brightness: brightness,
        );

    final ColorScheme infoScheme = dynamicInfo ?? ColorScheme.fromSeed(
          seedColor: _infoSeed,
          brightness: brightness,
        );

    final ColorScheme neutralScheme =
        dynamicNeutral ?? ColorScheme.fromSeed(
          seedColor: _neutralSeed,
          brightness: brightness,
        );

    final AppPalettes palettes = AppPalettes.fromSeeds(
      base: baseScheme,
      success: successScheme,
      warning: warningScheme,
      info: infoScheme,
      neutral: neutralScheme,
    );

    final TextTheme textTheme = _buildTextTheme(brightness, baseScheme);

    final Color scaffold = Color.alphaBlend(
      baseScheme.primary.withOpacity(brightness == Brightness.light ? 0.04 : 0.12),
      baseScheme.surface,
    );

    final Color cardColor = Color.alphaBlend(
      baseScheme.secondary.withOpacity(brightness == Brightness.light ? 0.05 : 0.18),
      baseScheme.surface,
    );

    final BorderRadius defaultRadius = BorderRadius.circular(24);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: baseScheme,
      textTheme: textTheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: scaffold,
      canvasColor: baseScheme.surface,
      extensions: <ThemeExtension<dynamic>>[palettes],
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: baseScheme.onSurface,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: cardColor,
        shadowColor: baseScheme.shadow.withOpacity(0.25),
        surfaceTintColor: baseScheme.surfaceTint,
        shape: ContinuousRectangleBorder(borderRadius: defaultRadius),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: baseScheme.onPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        backgroundColor: baseScheme.primaryContainer.withOpacity(0.5),
        selectedColor: palettes.success.primaryContainer,
        secondarySelectedColor: palettes.warning.primaryContainer,
        side: BorderSide(color: baseScheme.outlineVariant.withOpacity(0.35)),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: cardColor,
        elevation: 0,
        shape: ContinuousRectangleBorder(borderRadius: defaultRadius),
        titleTextStyle:
            textTheme.titleLarge?.copyWith(color: baseScheme.onSurface),
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: baseScheme.onSurfaceVariant),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 6,
        highlightElevation: 10,
        backgroundColor: baseScheme.primaryContainer,
        foregroundColor: baseScheme.onPrimaryContainer,
        shape: const StadiumBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          shape: ContinuousRectangleBorder(borderRadius: defaultRadius),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          backgroundColor: baseScheme.primary,
          foregroundColor: baseScheme.onPrimary,
          shadowColor: baseScheme.shadow.withOpacity(0.2),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          shape: ContinuousRectangleBorder(borderRadius: defaultRadius),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          side: BorderSide(color: baseScheme.outline.withOpacity(0.6), width: 1.4),
          shape: ContinuousRectangleBorder(borderRadius: defaultRadius),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color.alphaBlend(
          baseScheme.primary.withOpacity(0.05),
          baseScheme.surface,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: BorderSide(color: baseScheme.outline.withOpacity(0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: BorderSide(color: baseScheme.outlineVariant.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: BorderSide(color: baseScheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: BorderSide(color: palettes.warning.primary, width: 1.6),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: defaultRadius,
          borderSide: BorderSide(color: palettes.warning.primary, width: 1.8),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          foregroundColor: baseScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: ContinuousRectangleBorder(borderRadius: defaultRadius),
        tileColor: cardColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        iconColor: baseScheme.primary,
        textColor: baseScheme.onSurface,
      ),
    );
  }

  static TextTheme _buildTextTheme(
    Brightness brightness,
    ColorScheme colorScheme,
  ) {
    final TextTheme base =
        brightness == Brightness.dark ? Typography.whiteCupertino : Typography.blackCupertino;

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 54,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.05,
        color: colorScheme.onSurface,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.08,
        color: colorScheme.onSurface,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        height: 1.1,
        color: colorScheme.onSurface,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: colorScheme.onSurface,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colorScheme.onSurfaceVariant,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.25,
        color: colorScheme.onSurface,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: colorScheme.onSurfaceVariant,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.onPrimary,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: colorScheme.onSecondaryContainer,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
