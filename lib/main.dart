import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'ui/quantum_theme.dart';
import 'router.dart';
import 'models/contact.dart';
import 'providers/contact_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('Starting app initialization...');

  // Initialize Isar database
  final dir = await getApplicationDocumentsDirectory();
  print('Documents directory: ${dir.path}');

  final isar = await Isar.open(
    [ContactSchema],
    directory: dir.path,
  );

  print('Isar initialized successfully');

  // Set system UI overlay style for immersive experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: QuantumTheme.deepSpace,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  print('Launching app...');

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isar),
      ],
      child: const QuantumCardScannerApp(),
    ),
  );

  print('App launched successfully');
}

class QuantumCardScannerApp extends StatelessWidget {
  const QuantumCardScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Quantum Card Scanner',
      debugShowCheckedModeBanner: false,
      theme: QuantumTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
