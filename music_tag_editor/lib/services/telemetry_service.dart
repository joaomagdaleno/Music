import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:music_hub/firebase_options.dart';
import 'package:music_hub/core/services/startup_logger.dart';

/// A service for handling telemetry and error reporting in the Music project.
class TelemetryService {
  static final TelemetryService instance = TelemetryService._();
  TelemetryService._();

  bool _initialized = false;

  /// Initializes Firebase and Crashlytics.
  Future<void> init() async {
    if (_initialized) return;

    try {
      // Initialize with platform-specific options (required for Windows)
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

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
      StartupLogger.log('TelemetryService initialized');
    } catch (e) {
      StartupLogger.log('Failed to initialize TelemetryService: $e');
      // Do not rethrow, allow app to run without telemetry
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
      StartupLogger.log('Error: $exception');
    }
  }
}
