import 'package:flutter/material.dart';
import 'package:music_tag_editor/views/app_shell.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/services/dynamic_theme_service.dart';
import 'package:music_tag_editor/services/desktop_integration_service.dart';
import 'package:music_tag_editor/src/rust/frb_generated.dart';
import 'dart:async';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Rust Library
    await RustLib.init();

    // Initialize Core Services
    await ThemeService.instance.init();
    await DesktopIntegrationService.instance.init();

    runApp(const MusicTagEditorApp());
  }, (error, stack) {
    debugPrint('Fatal error: $error');
  });
}

class MusicTagEditorApp extends StatelessWidget {
  const MusicTagEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ThemeService.instance, DynamicThemeService.instance]),
      builder: (context, child) {
        final baseColor = ThemeService.instance.primaryColor;
        // Se a cor dinâmica for diferente do padrão, usa ela (caso tenha álbum tocando)
        final dynamicColor = DynamicThemeService.instance.primaryColor != Colors.deepPurple 
            ? DynamicThemeService.instance.primaryColor 
            : baseColor;
            
        return MaterialApp(
          title: 'Music Tag Editor',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: dynamicColor,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: dynamicColor,
              brightness: Brightness.dark,
            ),
          ),
          home: const AppShell(),
        );
      },
    );
  }
}
