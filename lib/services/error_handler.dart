import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'logger_service.dart';

/// Centralized error handling service for the application
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();

  factory ErrorHandler() => _instance;

  ErrorHandler._internal();

  final LoggerService _logger = LoggerService();

  /// Initialize error handling
  void initialize() {
    // Set up Flutter error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        // In debug mode, use the default Flutter error widget
        FlutterError.dumpErrorToConsole(details);
      } else {
        // In release mode, report to error tracking service
        _handleFlutterError(details);
      }
    };

    // Set up platform error handling (non-Flutter errors)
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true; // Prevent default error handling
    };

    _logger.info('Error handler initialized');
  }

  /// Handle Flutter framework errors
  void _handleFlutterError(FlutterErrorDetails details) {
    _logger.error(
      'Flutter Error: ${details.exception}',
      error: details.exception,
      stackTrace: details.stack,
    );

    // TODO: Send to crash reporting service (e.g., Firebase Crashlytics)
    // FirebaseCrashlytics.instance.recordFlutterError(details);
  }

  /// Handle platform/Dart errors
  void _handlePlatformError(Object error, StackTrace stack) {
    _logger.error(
      'Platform Error: $error',
      error: error,
      stackTrace: stack,
    );

    // TODO: Send to crash reporting service
    // FirebaseCrashlytics.instance.recordError(error, stack);
  }

  /// Handle custom application errors
  Future<void> handleError({
    required String message,
    Object? error,
    StackTrace? stackTrace,
    ErrorSeverity severity = ErrorSeverity.error,
    Map<String, dynamic>? context,
  }) async {
    switch (severity) {
      case ErrorSeverity.warning:
        _logger.warning(message, error: error, stackTrace: stackTrace);
        break;
      case ErrorSeverity.error:
        _logger.error(message, error: error, stackTrace: stackTrace);
        break;
      case ErrorSeverity.fatal:
        _logger.fatal(message, error: error, stackTrace: stackTrace);
        break;
    }

    if (context != null) {
      _logger.debug('Error context: $context');
    }

    // Report to external service in production
    if (kReleaseMode && severity != ErrorSeverity.warning) {
      await _reportToExternalService(
        message: message,
        error: error,
        stackTrace: stackTrace,
        context: context,
      );
    }
  }

  /// Report error to external service (prepared for Firebase Crashlytics)
  Future<void> _reportToExternalService({
    required String message,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) async {
    try {
      // TODO: Implement when Firebase is added
      // if (context != null) {
      //   context.forEach((key, value) {
      //     FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
      //   });
      // }
      // if (error != null) {
      //   await FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: message);
      // }
    } catch (e) {
      _logger.warning('Failed to report error to external service: $e');
    }
  }

  /// Show user-friendly error dialog
  void showErrorDialog(BuildContext context, AppError appError) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              appError.severity == ErrorSeverity.warning
                  ? Icons.warning_amber
                  : Icons.error_outline,
              color: appError.severity == ErrorSeverity.warning
                  ? Colors.orange
                  : Colors.red,
            ),
            const SizedBox(width: 8),
            const Text('Error'),
          ],
        ),
        content: Text(appError.userMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (appError.recoveryAction != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                appError.recoveryAction?.call();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  /// Show error snackbar
  void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

/// Error severity levels
enum ErrorSeverity {
  warning,
  error,
  fatal,
}

/// Custom application error class
class AppError {
  final String userMessage;
  final String? technicalMessage;
  final Object? error;
  final StackTrace? stackTrace;
  final ErrorSeverity severity;
  final VoidCallback? recoveryAction;
  final Map<String, dynamic>? context;

  AppError({
    required this.userMessage,
    this.technicalMessage,
    this.error,
    this.stackTrace,
    this.severity = ErrorSeverity.error,
    this.recoveryAction,
    this.context,
  });

  @override
  String toString() {
    return 'AppError{userMessage: $userMessage, technicalMessage: $technicalMessage, severity: $severity}';
  }
}

/// Predefined app errors
class AppErrors {
  static AppError networkError({VoidCallback? retry}) => AppError(
        userMessage: 'Network connection failed. Please check your internet connection.',
        technicalMessage: 'Network request failed',
        severity: ErrorSeverity.error,
        recoveryAction: retry,
      );

  static AppError cameraPermissionDenied() => AppError(
        userMessage: 'Camera permission is required to scan business cards.',
        technicalMessage: 'Camera permission denied by user',
        severity: ErrorSeverity.warning,
      );

  static AppError ocrFailed({Object? error}) => AppError(
        userMessage: 'Failed to process the card image. Please try again.',
        technicalMessage: 'OCR processing failed',
        error: error,
        severity: ErrorSeverity.error,
      );

  static AppError databaseError({Object? error}) => AppError(
        userMessage: 'Failed to save contact. Please try again.',
        technicalMessage: 'Database operation failed',
        error: error,
        severity: ErrorSeverity.error,
      );

  static AppError exportFailed({Object? error}) => AppError(
        userMessage: 'Failed to export contacts. Please try again.',
        technicalMessage: 'Export operation failed',
        error: error,
        severity: ErrorSeverity.error,
      );

  static AppError importFailed({Object? error}) => AppError(
        userMessage: 'Failed to import contacts. Please check the file format.',
        technicalMessage: 'Import operation failed',
        error: error,
        severity: ErrorSeverity.error,
      );

  static AppError invalidInput(String field) => AppError(
        userMessage: 'Invalid $field. Please check your input.',
        technicalMessage: 'Input validation failed for $field',
        severity: ErrorSeverity.warning,
      );

  static AppError unknown({Object? error, StackTrace? stackTrace}) => AppError(
        userMessage: 'An unexpected error occurred. Please try again.',
        technicalMessage: 'Unknown error: ${error.toString()}',
        error: error,
        stackTrace: stackTrace,
        severity: ErrorSeverity.error,
      );
}
