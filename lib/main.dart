import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app_theme.dart';
import 'router_showcase.dart';
import 'providers/settings_provider.dart';
import 'services/monetization/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Mobile Ads SDK only on mobile platforms
  if (!kIsWeb) {
    await MobileAds.instance.initialize();

    // Initialize our ad service
    await AdService().initialize();
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'CardScan',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: showcaseRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
