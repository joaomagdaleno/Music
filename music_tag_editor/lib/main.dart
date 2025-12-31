import 'dart:async';

import 'package:flutter/material.dart';
import 'package:music_tag_editor/services/auth_service.dart';
import 'package:music_tag_editor/services/connectivity_service.dart';
import 'package:music_tag_editor/services/desktop_integration_service.dart';
import 'package:music_tag_editor/services/persona_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/security_service.dart';
import 'package:music_tag_editor/services/startup_logger.dart';
import 'package:music_tag_editor/services/telemetry_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/views/app_shell.dart';
import 'package:music_tag_editor/screens/login/login_screen.dart';



void main() {
  runZonedGuarded(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      runApp(const AppBootstrap());
    },
    (error, stack) {
      debugPrint('🔥 [FATAL] Global runZonedGuarded error: $error');
      debugPrint(stack.toString());
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
      // Initialize StartupLogger first
      await StartupLogger.init();
      await StartupLogger.log('🚀 App initialization started');

      // Initialize Telemetry
      _updateStep('Initializing Telemetry...');
      try {
        await TelemetryService.instance.init();
        await StartupLogger.log('✅ TelemetryService initialized');
      } catch (e) {
        debugPrint('Telemetry init failed: $e');
        await StartupLogger.log('❌ Telemetry init failed: $e');
      }

      // Initialize Core Services
      _updateStep('Initializing Core Services...');
      try {
        await SecurityService.instance.init();
        AuthService.instance.init();
        await ConnectivityService.instance.init();
        await PersonaService.instance.init();

        await ThemeService.instance.init();
        await DesktopIntegrationService.instance.init();
        await PlaybackService.instance.init();
        await StartupLogger.log('✅ Core services initialized successfully');
      } catch (e) {
        debugPrint('Service initialization failed: $e');
        await StartupLogger.log('❌ Service initialization failed: $e');
      }

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
              'Initialization failed: $e\n\nCheck startup_log.txt for details.';
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
  final TargetPlatform? platform;
  const MusicTagEditorApp({super.key, this.platform});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, child) {
        final primaryColor = ThemeService.instance.primaryColor;
        return MaterialApp(
          title: 'Music Tag Editor',
          theme: ThemeData(
            useMaterial3: true,
            platform: platform,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            platform: platform,
            colorScheme: ColorScheme.fromSeed(
              seedColor: primaryColor,
              brightness: Brightness.dark,
            ),
          ),
          home: AuthService.instance.isAuthenticated
              ? const AppShell()
              : const LoginScreen(),
        );
      },
    );
  }
}


