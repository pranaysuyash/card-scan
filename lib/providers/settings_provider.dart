import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}

final apiKeyProvider = StateNotifierProvider<ApiKeyNotifier, String?>((ref) {
  return ApiKeyNotifier(ref);
});

class ApiKeyNotifier extends StateNotifier<String?> {
  final Ref ref;

  ApiKeyNotifier(this.ref) : super(null) {
    _loadKey();
  }

  Future<void> _loadKey() async {
    final storage = ref.read(secureStorageProvider);
    state = await storage.read(key: 'openai_api_key');
  }

  Future<void> setKey(String key) async {
    final storage = ref.read(secureStorageProvider);
    await storage.write(key: 'openai_api_key', value: key);
    state = key;
  }

  Future<void> deleteKey() async {
    final storage = ref.read(secureStorageProvider);
    await storage.delete(key: 'openai_api_key');
    state = null;
  }
}

final deleteImagesAfterOCRProvider = StateProvider<bool>((ref) => true);
final sortModeProvider = StateProvider<SortMode>((ref) => SortMode.recent);

enum SortMode {
  recent,
  name,
  company,
}
