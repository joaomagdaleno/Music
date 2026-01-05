import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:music_tag_editor/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:music_tag_editor/services/auth_service.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:music_tag_editor/services/connectivity_service.dart';
import 'package:music_tag_editor/services/desktop_integration_service.dart';
import 'package:music_tag_editor/services/persona_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/security_service.dart';
import 'package:music_tag_editor/services/startup_logger.dart';
import 'package:music_tag_editor/services/telemetry_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/widgets/mini_player.dart';
import 'package:music_tag_editor/views/app_shell.dart';
// Removed media_kit

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runZonedGuarded(
    () async {
      ErrorWidget.builder = (FlutterErrorDetails details) {
            if (!kIsWeb && Platform.isWindows) {
              return fluent.FluentApp(
                home: fluent.ScaffoldPage(
                  header: const fluent.PageHeader(title: Text('Error')),
                  content: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        details.exceptionAsString(),
                        style: const TextStyle(color: fluent.Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              );
            }
            return MaterialApp(
              home: Scaffold(
                // Accessibility: Use muted dark color instead of aggressive red
                // Avoids photosensitivity issues and is easier for colorblind users
                backgroundColor: const Color(0xFF424242), // Grey 800
                body: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      details.exceptionAsString(),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
            );
          };

      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      runApp(const AppBootstrap());
    },
    (error, stack) {
      StartupLogger.log('🔥 [FATAL] Global error: $error');
      StartupLogger.log(stack.toString());
      try {
        TelemetryService.instance.recordError(error, stack);
      } catch (e) {
        debugPrint('Fallback recordError failed: $e');
        StartupLogger.log('❌ Fallback recordError failed: $e');
      }
    },
  );
}

// ... (imports)

/// Bootstrap widget that handles async initialization and shows a splash
/// screen.
class AppBootstrap extends StatefulWidget {
  /// Creates a new instance of [AppBootstrap].
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _isInitialized = false;
  String? _errorMessage;
  String _currentStep = 'Starting...';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 1. Initialize Logger (Critical for debugging)
      await StartupLogger.init();
      await StartupLogger.log('🚀 App initialization started');

      // 2. Non-Critical Services (Fail safe)
      _updateStep('Initializing Telemetry...');
      try {
        await TelemetryService.instance.init();
        StartupLogger.log('✅ TelemetryService initialized');
      } catch (e) {
        StartupLogger.log('⚠️ Telemetry init failed (Non-critical): $e');
      }

      // 3. Critical Services (Must succeed)
      _updateStep('Initializing Core Services...');
      
      await StartupLogger.log('Initializing SecurityService...');
      await SecurityService.instance.init();

      await StartupLogger.log('Initializing DependencyManager...');
      await DependencyManager.instance.ensureDependencies();

      await StartupLogger.log('Initializing AuthService...');
      AuthService.instance.init();

      await StartupLogger.log('Initializing ConnectivityService...');
      await ConnectivityService.instance.init();

      await StartupLogger.log('Initializing PersonaService...');
      await PersonaService.instance.init();

      await StartupLogger.log('Initializing ThemeService...');
      await ThemeService.instance.init();

      // Desktop Integration is platform specific but usually safe to fail if wrapped,
      // but we'll treat as non-critical or semi-critical. Let's keep it here for now.
      await StartupLogger.log('Initializing DesktopIntegrationService...');
      await DesktopIntegrationService.instance.init();

      // Creating a boundary for PlaybackService as it interacts with hardware
      StartupLogger.log('Initializing PlaybackService...');
      try {
        await PlaybackService.instance.init();
      } catch (e) {
         // If playback fails, the app is useless as a music player. 
         // Rethrow to trigger fatal error screen.
         StartupLogger.log('❌ PlaybackService failed (CRITICAL): $e');
         throw Exception('Audio Engine failed to initialize: $e');
      }

      await StartupLogger.log('✅ Core services initialized successfully');

      await StartupLogger.log('🚀 App initialization complete, launching UI');

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e, stack) {
      await StartupLogger.log('🔥 FATAL: App initialization failed: $e');
      await StartupLogger.log(stack.toString());

      if (mounted) {
        setState(() {
          _errorMessage =
              'Critical Initialization Failed:\n$e\n\nPlease check logs at:\n${StartupLogger.logFilePath}';
        });
      }
    }
  }

  void _updateStep(String step) {
    if (mounted) {
      setState(() {
        _currentStep = step;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Music Tag Editor - Error',
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _isInitialized = false;
                        _currentStep = 'Retrying...';
                      });
                      _initializeApp();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Music Tag Editor - Loading',
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(_currentStep, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    }

    return const MusicTagEditorApp();
  }
}

class MusicTagEditorApp extends StatelessWidget {
  const MusicTagEditorApp({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: ThemeService.instance,
        builder: (context, child) {
          final primaryColor = ThemeService.instance.primaryColor;
          if (Platform.isWindows) {
            return fluent.FluentApp(
              title: 'Music Tag Editor',
              themeMode: fluent.ThemeMode.system,
              darkTheme: fluent.FluentThemeData(
                brightness: fluent.Brightness.dark,
                accentColor: fluent.Colors.blue,
                scaffoldBackgroundColor: const fluent.Color(0xFF1E1E1E),
              ),
              theme: fluent.FluentThemeData(
                brightness: fluent.Brightness.light,
                accentColor: fluent.Colors.blue,
                scaffoldBackgroundColor: fluent.Colors.white,
              ),
              home: const AppShell(),
              navigatorKey: appNavigatorKey,
              builder: (context, child) => Stack(
                children: [
                  child ?? const SizedBox.shrink(),
                  const Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: MiniPlayer(),
                  ),
                ],
              ),
            );
          }

          return MaterialApp(
            title: 'Music Tag Editor',
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.white,
              colorScheme: ColorScheme.fromSeed(
                seedColor: primaryColor,
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.black,
              colorScheme: ColorScheme.fromSeed(
                seedColor: primaryColor,
                brightness: Brightness.dark,
              ),
            ),
            home: const AppShell(),
            navigatorKey: appNavigatorKey,
            builder: (context, child) => Material(
              child: Stack(
                children: [
                  child ?? const SizedBox.shrink(),
                  const Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: MiniPlayer(),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

