@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_hub/models/filename_format.dart';
import 'package:music_hub/views/app_shell.dart';
import 'package:music_hub/services/persona_service.dart';
import 'package:music_hub/models/persona_model.dart';
import 'package:music_hub/core/services/database_service.dart';
import 'package:music_hub/core/services/theme_service.dart';
import 'package:music_hub/core/services/connectivity_service.dart';
import 'package:music_hub/services/auth_service.dart';
import 'package:music_hub/features/player/services/playback_service.dart';
import 'package:music_hub/services/security_service.dart';
import 'package:music_hub/services/desktop_integration_service.dart';
import 'package:music_hub/core/services/dependency_manager.dart';
import 'package:music_hub/features/discovery/services/download_service.dart';
// import 'package:media_kit/media_kit.dart'; // Unused
import 'test_helper.dart';

class MockAuthService extends Mock implements AuthService {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockThemeService extends Mock implements ThemeService {}

class MockPlaybackService extends Mock implements PlaybackService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSecurityService extends Mock implements SecurityService {}

class MockDesktopIntegrationService extends Mock
    implements DesktopIntegrationService {}
// Removed MockAudioPlayer

void main() {
  late MockAuthService mockAuth;
  late MockDatabaseService mockDb;
  late MockThemeService mockTheme;
  late MockPlaybackService mockPlayback;
  late MockConnectivityService mockConnectivity;
  late MockSecurityService mockSecurity;
  late MockDesktopIntegrationService mockDesktop;
  late MockPlayer
      mockAudioPlayer; // Renamed to keep usage consistent if it was mockAudioPlayer

  setUp(() {
    mockAuth = MockAuthService();
    mockDb = MockDatabaseService();
    mockTheme = MockThemeService();
    mockConnectivity = MockConnectivityService();
    mockPlayback = MockPlaybackService();
    mockSecurity = MockSecurityService();
    mockDesktop = MockDesktopIntegrationService();
    mockAudioPlayer = MockPlayer();

    DatabaseService.instance = mockDb;
    ThemeService.instance = mockTheme;
    ConnectivityService.instance = mockConnectivity;
    AuthService.instance = mockAuth;
    PlaybackService.instance = mockPlayback;
    SecurityService.instance = mockSecurity;
    DesktopIntegrationService.instance = mockDesktop;
    DependencyManager.instance = mockDeps;
    DownloadService.instance = mockDownload;
    PersonaService.resetInstance();

    when(() => mockTheme.primaryColor).thenReturn(Colors.blue);
    when(() => mockTheme.addListener(any())).thenReturn(null);
    when(() => mockTheme.removeListener(any())).thenReturn(null);
    when(() => mockTheme.useCustomColor).thenReturn(false);
    when(() => mockConnectivity.isOffline).thenReturn(ValueNotifier(false));
    when(() => mockDb.loadFilenameFormat())
        .thenAnswer((_) async => FilenameFormat.artistTitle);
    when(() => mockDb.loadCrossfadeDuration()).thenAnswer((_) async => 3);
    when(() => mockDb.loadAgeBypass()).thenAnswer((_) async => false);
    when(() => mockDb.getSetting(any())).thenAnswer((_) async => null);
    when(() => mockDb.saveSetting(any(), any())).thenAnswer((_) async {});
    when(() => mockDb.getTracks()).thenAnswer((_) async => []);
    when(() => mockDb.getPlaylists()).thenAnswer((_) async => []);
    // Fake streams
    final fakeStream = FakePlayerStream();
    when(() => mockAudioPlayer.stream).thenReturn(fakeStream);

    // Stub individual streams via the fake if accessed directly (though test might access via stream property)
    // If the test accesses `mockPlayer.playerStateStream` (old API), we must remove that.
    // Assuming the test code under verification has been updated, we just need to ensure generic stream access works.

    when(() => mockAuth.isAuthenticated).thenReturn(false);
    when(() => mockPlayback.player).thenReturn(mockAudioPlayer);
    when(() => mockPlayback.currentTrack).thenReturn(null);
    when(() => mockPlayback.currentTrackStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockPlayback.lyricsStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockPlayback.currentLyrics).thenReturn([]);
  });

  Widget createWidgetUnderTest(Widget home) => MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: home,
      );

  group('Global Navigation (AppShell)', () {
    testWidgets('Displays global navigation items in AppShell', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetUnderTest(const AppShell()));
      await tester.pump();

      expect(find.text('Início'), findsAtLeastNWidgets(1));
      expect(find.text('Buscar'), findsAtLeastNWidgets(1));
      expect(find.text('Bibliotecário'), findsAtLeastNWidgets(1));
      expect(find.text('Anfitrião'), findsAtLeastNWidgets(1));
      expect(find.text('Artesão'), findsAtLeastNWidgets(1));
    });

    testWidgets('Switching persona updates PersonaService', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetUnderTest(const AppShell()));
      await tester.pumpAndSettle();

      // Default persona is librarian
      expect(PersonaService.instance.activePersona, AppPersona.librarian);

      // Tap persona in nav bar - use a more robust finder
      final navBarItem = find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('Anfitrião'),
      );

      expect(navBarItem, findsOneWidget);
      await tester.tap(navBarItem);
      await tester.pump(const Duration(milliseconds: 500));

      expect(PersonaService.instance.activePersona, AppPersona.host);

      PersonaService.instance.setPersona(AppPersona.librarian);
    });
  });

  group('AppShell Persona Features', () {
    testWidgets('AppShell shows Home screen by default', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetUnderTest(const AppShell()));
      await tester.pumpAndSettle();

      expect(find.text('Minhas Personas'), findsOneWidget);
    });

    testWidgets('Librarian persona includes Playlists', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      PersonaService.instance.setPersona(AppPersona.librarian);
      await tester.pumpWidget(createWidgetUnderTest(const AppShell()));
      await tester.pumpAndSettle();

      // Select Librarian persona via Nav Bar
      final libItem = find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('Bibliotecário'),
      );
      await tester.tap(libItem);
      await tester.pump(const Duration(milliseconds: 500));

      // The persona shell shows tabs. "Playlists" is one of them.
      expect(find.text('Playlists'), findsAtLeastNWidgets(1));
    });
  });

  group('Home Screen Interaction', () {
    testWidgets('Tapping persona card on Home screen switches persona',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidgetUnderTest(const AppShell()));
      await tester.pump();

      // Tap "Anfitrião" card on Home screen (should be first instance)
      await tester.tap(find.text('Anfitrião').first);
      await tester.pump(const Duration(milliseconds: 500));

      expect(PersonaService.instance.activePersona, AppPersona.host);
    });
  });
}
