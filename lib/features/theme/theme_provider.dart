import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode state
enum AppThemeMode {
  light,
  dark,
  system,
}

/// Theme provider for managing app theme
class ThemeNotifier extends StateNotifier<AppThemeMode> {
  static const String _themeKey = 'app_theme_mode';

  ThemeNotifier() : super(AppThemeMode.dark) {
    _loadTheme();
  }

  /// Load saved theme preference
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeName = prefs.getString(_themeKey);

      if (themeName != null) {
        state = AppThemeMode.values.firstWhere(
          (mode) => mode.name == themeName,
          orElse: () => AppThemeMode.dark,
        );
      }
    } catch (e) {
      // Default to dark theme if loading fails
      state = AppThemeMode.dark;
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Toggle between light and dark
  Future<void> toggleTheme() async {
    final newMode = state == AppThemeMode.light
        ? AppThemeMode.dark
        : AppThemeMode.light;
    await setThemeMode(newMode);
  }

  bool get isDark => state == AppThemeMode.dark;
  bool get isLight => state == AppThemeMode.light;
  bool get isSystem => state == AppThemeMode.system;
}

/// Provider for theme state
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>(
  (ref) => ThemeNotifier(),
);
