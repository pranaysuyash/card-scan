import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'ui/quantum_theme.dart';
import 'router.dart';
import 'models/contact.dart';
import 'providers/contact_provider.dart';
import 'services/error_handler.dart';
import 'services/logger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize error handling and logging
  final errorHandler = ErrorHandler();
  final logger = LoggerService();
  errorHandler.initialize();

  logger.info('Starting app initialization...');

  try {
    // Initialize Isar database
    final dir = await getApplicationDocumentsDirectory();
    logger.info('Documents directory: ${dir.path}');

    final isar = await Isar.open(
      [ContactSchema],
      directory: dir.path,
    );

    logger.info('Isar initialized successfully');

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

    logger.info('Launching app...');

    runApp(
      ProviderScope(
        overrides: [
          isarProvider.overrideWithValue(isar),
        ],
        child: const QuantumCardScannerApp(),
      ),
    );

    logger.info('App launched successfully');
  } catch (error, stackTrace) {
    logger.fatal('Failed to initialize app', error: error, stackTrace: stackTrace);
    errorHandler.handleError(
      message: 'App initialization failed',
      error: error,
      stackTrace: stackTrace,
      severity: ErrorSeverity.fatal,
    );

    // Show a fallback error screen
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 24),
                  const Text(
                    'Failed to start app',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    error.toString(),
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
