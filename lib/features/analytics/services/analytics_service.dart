import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Comprehensive analytics service
/// Tracks user behavior, performance, and errors
class AnalyticsService {
  static const String mixpanelToken = 'YOUR_MIXPANEL_TOKEN';
  static const String sentryDsn = 'YOUR_SENTRY_DSN';

  final FirebaseAnalytics _firebaseAnalytics = FirebaseAnalytics.instance;
  Mixpanel? _mixpanel;

  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Initialize analytics services
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize Mixpanel
      _mixpanel = await Mixpanel.init(
        mixpanelToken,
        trackAutomaticEvents: true,
      );

      // Initialize Sentry
      await SentryFlutter.init(
        (options) {
          options.dsn = sentryDsn;
          options.tracesSampleRate = 1.0;
          options.enableAutoPerformanceTracing = true;
        },
      );

      _initialized = true;
    } catch (e) {
      // Silently fail analytics initialization
    }
  }

  // ============================================
  // USER IDENTIFICATION
  // ============================================

  /// Identify user across platforms
  Future<void> identifyUser(String userId, {Map<String, dynamic>? properties}) async {
    try {
      await _firebaseAnalytics.setUserId(id: userId);
      _mixpanel?.identify(userId);

      if (properties != null) {
        for (final entry in properties.entries) {
          await _firebaseAnalytics.setUserProperty(
            name: entry.key,
            value: entry.value.toString(),
          );
        }
        _mixpanel?.getPeople().set('\$name', properties['name']);
        _mixpanel?.getPeople().set('\$email', properties['email']);
      }

      Sentry.configureScope((scope) {
        scope.setUser(SentryUser(id: userId));
      });
    } catch (e) {
      // Silently fail
    }
  }

  // ============================================
  // EVENT TRACKING
  // ============================================

  /// Track scan completed
  Future<void> trackScanCompleted({
    required int durationMs,
    required double confidence,
    required String ocrEngine,
  }) async {
    await _trackEvent('scan_completed', {
      'duration_ms': durationMs,
      'confidence': confidence,
      'ocr_engine': ocrEngine,
    });
  }

  /// Track contact saved
  Future<void> trackContactSaved(String source) async {
    await _trackEvent('contact_saved', {'source': source});
  }

  /// Track export
  Future<void> trackExport(String format, int contactCount) async {
    await _trackEvent('export', {
      'format': format,
      'contact_count': contactCount,
    });
  }

  /// Track search performed
  Future<void> trackSearch(String query, int resultsCount) async {
    await _trackEvent('search', {
      'query_length': query.length,
      'results_count': resultsCount,
    });
  }

  /// Track batch processing
  Future<void> trackBatchProcessing({
    required int cardCount,
    required int successCount,
    required int failureCount,
    required int durationMs,
  }) async {
    await _trackEvent('batch_processing', {
      'card_count': cardCount,
      'success_count': successCount,
      'failure_count': failureCount,
      'duration_ms': durationMs,
    });
  }

  /// Track QR code shared
  Future<void> trackQrCodeShared() async {
    await _trackEvent('qr_code_shared', {});
  }

  /// Track deduplication
  Future<void> trackDeduplication({
    required int duplicatesFound,
    required int merged,
  }) async {
    await _trackEvent('deduplication', {
      'duplicates_found': duplicatesFound,
      'merged': merged,
    });
  }

  /// Track voice note
  Future<void> trackVoiceNote({
    required int durationSec,
    required bool transcribed,
  }) async {
    await _trackEvent('voice_note', {
      'duration_sec': durationSec,
      'transcribed': transcribed,
    });
  }

  // ============================================
  // SUBSCRIPTION EVENTS
  // ============================================

  /// Track subscription view
  Future<void> trackSubscriptionView() async {
    await _trackEvent('subscription_view', {});
  }

  /// Track purchase attempt
  Future<void> trackPurchaseAttempt(String productId) async {
    await _trackEvent('purchase_attempt', {
      'product_id': productId,
    });
  }

  /// Track purchase success
  Future<void> trackPurchaseSuccess(String productId, double price) async {
    await _firebaseAnalytics.logPurchase(
      currency: 'USD',
      value: price,
    );
    await _trackEvent('purchase_success', {
      'product_id': productId,
      'price': price,
    });
  }

  /// Track purchase cancelled
  Future<void> trackPurchaseCancelled(String productId) async {
    await _trackEvent('purchase_cancelled', {
      'product_id': productId,
    });
  }

  // ============================================
  // PERFORMANCE TRACKING
  // ============================================

  /// Track OCR duration
  Future<void> trackOcrDuration(int milliseconds) async {
    await _trackEvent('ocr_duration', {'duration_ms': milliseconds});
  }

  /// Track app launch time
  Future<void> trackAppLaunchTime(int milliseconds) async {
    await _trackEvent('app_launch', {'duration_ms': milliseconds});
  }

  /// Track frame rate
  Future<void> trackFrameRate(double fps) async {
    await _trackEvent('frame_rate', {'fps': fps});
  }

  // ============================================
  // FEATURE USAGE
  // ============================================

  /// Track feature used
  Future<void> trackFeatureUsed(String featureName) async {
    await _trackEvent('feature_used', {'feature': featureName});
  }

  /// Track screen view
  Future<void> trackScreenView(String screenName) async {
    try {
      await _firebaseAnalytics.logScreenView(screenName: screenName);
      _mixpanel?.track('Screen View', properties: {'screen': screenName});
    } catch (e) {
      // Silently fail
    }
  }

  // ============================================
  // USER RETENTION
  // ============================================

  /// Track user retention
  Future<void> trackUserRetention(int daysActive) async {
    await _trackEvent('user_retention', {'days_active': daysActive});
  }

  /// Track session start
  Future<void> trackSessionStart() async {
    await _trackEvent('session_start', {});
  }

  /// Track session end
  Future<void> trackSessionEnd(int durationSec) async {
    await _trackEvent('session_end', {'duration_sec': durationSec});
  }

  // ============================================
  // ERROR TRACKING
  // ============================================

  /// Track error
  Future<void> trackError({
    required String error,
    required StackTrace stackTrace,
    Map<String, dynamic>? context,
  }) async {
    try {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: Hint.withMap(context ?? {}),
      );

      await _trackEvent('error', {
        'error_message': error.toString(),
        ...?context,
      });
    } catch (e) {
      // Silently fail
    }
  }

  /// Track crash
  Future<void> trackCrash({
    required dynamic exception,
    required StackTrace stackTrace,
    bool fatal = true,
  }) async {
    try {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        hint: Hint.withMap({'fatal': fatal}),
      );
    } catch (e) {
      // Silently fail
    }
  }

  // ============================================
  // PRIVATE METHODS
  // ============================================

  /// Track event to all platforms
  Future<void> _trackEvent(String name, Map<String, dynamic> properties) async {
    try {
      await _firebaseAnalytics.logEvent(name: name, parameters: properties);
      _mixpanel?.track(name, properties: properties);
    } catch (e) {
      // Silently fail
    }
  }

  /// Set user property
  Future<void> setUserProperty(String name, String value) async {
    try {
      await _firebaseAnalytics.setUserProperty(name: name, value: value);
      _mixpanel?.getPeople().set(name, value);
    } catch (e) {
      // Silently fail
    }
  }

  /// Increment user property
  Future<void> incrementUserProperty(String name, [int by = 1]) async {
    try {
      _mixpanel?.getPeople().increment(name, by);
    } catch (e) {
      // Silently fail
    }
  }
}
