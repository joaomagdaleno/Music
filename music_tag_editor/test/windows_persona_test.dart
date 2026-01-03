import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/views/app_shell.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:music_tag_editor/services/persona_service.dart';
import 'package:music_tag_editor/models/persona_model.dart';
import 'package:music_tag_editor/models/filename_format.dart';
import 'test_helper.dart';

void main() {
  group('Windows Persona Switching Tests', () {
    late ValueNotifier<bool> isOffline;

    setUp(() async {
      await setupMusicTest();
      isOffline = ValueNotifier<bool>(false);
      when(() => mockConnectivity.isOffline).thenReturn(isOffline);
      when(() => mockDb.getSetting(any())).thenAnswer((_) async => null);
      when(() => mockDb.getPlaylists()).thenAnswer((_) async => []);
      when(() => mockDb.getGuestHistory()).thenAnswer((_) async => []);
      when(() => mockDb.loadFilenameFormat()).thenAnswer((_) async => FilenameFormat.artistTitle);
      when(() => mockDb.getLearningRules()).thenAnswer((_) async => []);
      when(() => mockDb.getMostPlayed()).thenAnswer((_) async => []);
      when(() => mockAuth.isAuthenticated).thenReturn(true);
    });

    testWidgets('Switching persona on Windows updates view', (tester) async {
      // Set window size for Fluent UI
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      // Set platform to Windows
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      await tester.pumpWidget(fluent.FluentApp(
        home: const AppShell(),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(fluent.NavigationView), findsOneWidget);
      
      // Initial persona is HOME (screen contains "Bem-vindo de volta")
      expect(find.text('Bem-vindo de volta!'), findsOneWidget);

      // Find Librarian icon in navigation pane
      final libItem = find.byIcon(fluent.FluentIcons.library).first;
      expect(libItem, findsAtLeastNWidgets(1));
      
      // Tap Librarian icon
      await tester.tap(libItem);
      await tester.pumpAndSettle();

      // Should now be in Librarian persona.
      expect(PersonaService.instance.activePersona, AppPersona.librarian);
      
      // Look for any icon that identifies the Librarian persona view.
      // "Tags" icon is tag.
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byIcon(fluent.FluentIcons.tag), findsOneWidget);

      // Should also see "Biblioteca" icon
      expect(find.byIcon(fluent.FluentIcons.music_note), findsAtLeastNWidgets(1));

      // Tap "Anfitrião" (Host) icon
      await tester.tap(find.byIcon(fluent.FluentIcons.party_leader));
      await tester.pump(); // Use pump instead of pumpAndSettle because of DiscoModeScreen timer
      await tester.pump(const Duration(milliseconds: 500));

      // Should now be in Host persona.
      expect(PersonaService.instance.activePersona, AppPersona.host);

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
