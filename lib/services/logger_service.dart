import 'package:flutter/foundation.dart';

/// Centralized logging service for the application
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();

  factory LoggerService() => _instance;

  LoggerService._internal();

  static const String _appName = 'CardScanner';

  /// Log levels
  static const int _levelDebug = 0;
  static const int _levelInfo = 1;
  static const int _levelWarning = 2;
  static const int _levelError = 3;
  static const int _levelFatal = 4;

  /// Current minimum log level (only logs at or above this level are shown)
  int _minLevel = kDebugMode ? _levelDebug : _levelInfo;

  /// Log level names
  static const Map<int, String> _levelNames = {
    _levelDebug: 'DEBUG',
    _levelInfo: 'INFO',
    _levelWarning: 'WARN',
    _levelError: 'ERROR',
    _levelFatal: 'FATAL',
  };

  /// Log level colors for console output
  static const Map<int, String> _levelColors = {
    _levelDebug: '\x1B[37m', // White
    _levelInfo: '\x1B[36m', // Cyan
    _levelWarning: '\x1B[33m', // Yellow
    _levelError: '\x1B[31m', // Red
    _levelFatal: '\x1B[35m', // Magenta
  };

  static const String _colorReset = '\x1B[0m';

  /// Set minimum log level
  void setMinLevel(int level) {
    _minLevel = level;
  }

  /// Log a debug message
  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    _log(_levelDebug, message, error: error, stackTrace: stackTrace);
  }

  /// Log an info message
  void info(String message, {Object? error, StackTrace? stackTrace}) {
    _log(_levelInfo, message, error: error, stackTrace: stackTrace);
  }

  /// Log a warning message
  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    _log(_levelWarning, message, error: error, stackTrace: stackTrace);
  }

  /// Log an error message
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log(_levelError, message, error: error, stackTrace: stackTrace);
  }

  /// Log a fatal error message
  void fatal(String message, {Object? error, StackTrace? stackTrace}) {
    _log(_levelFatal, message, error: error, stackTrace: stackTrace);
  }

  /// Core logging method
  void _log(
    int level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level < _minLevel) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelName = _levelNames[level] ?? 'UNKNOWN';
    final color = kDebugMode ? _levelColors[level] : '';
    final reset = kDebugMode ? _colorReset : '';

    // Format the log message
    final logMessage = '$color[$timestamp] [$_appName] [$levelName] $message$reset';

    // Print to console
    if (kDebugMode) {
      debugPrint(logMessage);
    } else {
      print(logMessage);
    }

    // Print error if present
    if (error != null) {
      final errorMessage = '$color  ↳ Error: $error$reset';
      if (kDebugMode) {
        debugPrint(errorMessage);
      } else {
        print(errorMessage);
      }
    }

    // Print stack trace if present and level is error or fatal
    if (stackTrace != null && level >= _levelError) {
      final stackMessage = '$color  ↳ Stack trace:\n$stackTrace$reset';
      if (kDebugMode) {
        debugPrint(stackMessage);
      } else {
        print(stackMessage);
      }
    }

    // TODO: Send logs to external service in production
    if (kReleaseMode && level >= _levelError) {
      _sendToExternalService(level, message, error, stackTrace);
    }
  }

  /// Send logs to external service (prepared for Firebase, Sentry, etc.)
  void _sendToExternalService(
    int level,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    // TODO: Implement when analytics/logging service is added
    // Example for Firebase Analytics:
    // FirebaseAnalytics.instance.logEvent(
    //   name: 'app_error',
    //   parameters: {
    //     'level': _levelNames[level],
    //     'message': message,
    //   },
    // );
  }

  /// Log a performance metric
  void performance(String operation, Duration duration) {
    info('Performance: $operation took ${duration.inMilliseconds}ms');

    // TODO: Send to performance monitoring service
    // FirebasePerformance.instance.newTrace(operation)
    //   ..start()
    //   ..setMetric('duration_ms', duration.inMilliseconds)
    //   ..stop();
  }

  /// Log user action for analytics
  void userAction(String action, {Map<String, dynamic>? parameters}) {
    debug('User action: $action${parameters != null ? ' - $parameters' : ''}');

    // TODO: Send to analytics service
    // FirebaseAnalytics.instance.logEvent(
    //   name: action,
    //   parameters: parameters,
    // );
  }

  /// Log a custom event
  void event(String name, {Map<String, dynamic>? data}) {
    info('Event: $name${data != null ? ' - $data' : ''}');

    // TODO: Send to analytics service
  }
}

/// Mixin for easy logging in classes
mixin LoggerMixin {
  final LoggerService _logger = LoggerService();

  LoggerService get logger => _logger;

  void logDebug(String message) => _logger.debug(message);
  void logInfo(String message) => _logger.info(message);
  void logWarning(String message, {Object? error}) =>
      _logger.warning(message, error: error);
  void logError(String message, {Object? error, StackTrace? stackTrace}) =>
      _logger.error(message, error: error, stackTrace: stackTrace);
}
