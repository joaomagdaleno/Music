import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// A service for handling telemetry and error reporting in the Music project.
class TelemetryService {
  static final TelemetryService instance = TelemetryService._();
  TelemetryService._();

  bool _initialized = false;

  /// Initializes Firebase and Crashlytics.
  Future<void> init() async {
    if (_initialized) return;

    try {
      // NOTE: Music project needs Firebase Options for specialized initialization if not using default.
      // For now, we assume simple current platform initialization is configured in the environment.
      await Firebase.initializeApp();

      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(!kDebugMode);

        FlutterError.onError = (errorDetails) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        };

        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }

      _initialized = true;
      debugPrint('TelemetryService initialized');
    } catch (e) {
      debugPrint('Failed to initialize TelemetryService: $e');
    }
  }

  /// Logs a custom event.
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    if (!_initialized) return;
    await FirebaseAnalytics.instance
        .logEvent(name: name, parameters: parameters);
  }

  /// Records a non-fatal error.
  Future<void> recordError(dynamic exception, StackTrace? stack,
      {dynamic reason}) async {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      await FirebaseCrashlytics.instance
          .recordError(exception, stack, reason: reason);
    } else {
      debugPrint('Error: $exception');
    }
  }
}
