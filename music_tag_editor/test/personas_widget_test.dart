import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/views/settings_page.dart';
import 'package:music_tag_editor/views/app_shell.dart';
import 'package:music_tag_editor/services/persona_service.dart';
import 'package:music_tag_editor/models/persona_model.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/services/connectivity_service.dart';
import 'package:music_tag_editor/services/auth_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/security_service.dart';
import 'package:music_tag_editor/services/desktop_integration_service.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:just_audio/just_audio.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

class MockThemeService extends Mock implements ThemeService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockAuthService extends Mock implements AuthService {}

class MockPlaybackService extends Mock implements PlaybackService {}

class MockSecurityService extends Mock implements SecurityService {}

class MockDesktopIntegrationService extends Mock
    implements DesktopIntegrationService {}

class MockDependencyManager extends Mock implements DependencyManager {}

class MockDownloadService extends Mock implements DownloadService {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  late MockDatabaseService mockDb;
  late MockThemeService mockTheme;
  late MockConnectivityService mockConnectivity;
  late MockAuthService mockAuth;
  late MockPlaybackService mockPlayback;
  late MockSecurityService mockSecurity;
  late MockDesktopIntegrationService mockDesktop;
  late MockDependencyManager mockDeps;
  late MockDownloadService mockDownload;
  late MockAudioPlayer mockAudioPlayer;

  setUp(() {
    mockDb = MockDatabaseService();
    mockTheme = MockThemeService();
    mockConnectivity = MockConnectivityService();
    mockAuth = MockAuthService();
    mockPlayback = MockPlaybackService();
    mockSecurity = MockSecurityService();
    mockDesktop = MockDesktopIntegrationService();
    mockDeps = MockDependencyManager();
    mockDownload = MockDownloadService();
    mockAudioPlayer = MockAudioPlayer();

    DatabaseService.instance = mockDb;
    ThemeService.instance = mockTheme;
    ConnectivityService.instance = mockConnectivity;
    AuthService.instance = mockAuth;
    PlaybackService.instance = mockPlayback;
    SecurityService.instance = mockSecurity;
    DesktopIntegrationService.instance = mockDesktop;
    DependencyManager.instance = mockDeps;
    DownloadService.instance = mockDownload;

    // Default stubs
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

    when(() => mockAudioPlayer.playerStateStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockAudioPlayer.positionStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockAudioPlayer.bufferedPositionStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockAudioPlayer.durationStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockAudioPlayer.volumeStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockAudioPlayer.speedStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockAudioPlayer.shuffleModeEnabledStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockAudioPlayer.loopModeStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockAudioPlayer.sequenceStateStream)
        .thenAnswer((_) => const Stream.empty());

    when(() => mockPlayback.player).thenReturn(mockAudioPlayer);
    when(() => mockPlayback.currentTrack).thenReturn(null);
    when(() => mockPlayback.lyricsStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockPlayback.currentLyrics).thenReturn([]);
  });

  Widget createWidgetUnderTest(Widget home) {
    return MaterialApp(
      home: home,
    );
  }

  group('SettingsPage Persona Selection', () {
    testWidgets('Displays all persona options in SettingsPage', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const SettingsPage()));
      await tester.pump();

      expect(find.text('Modo do Sistema (Persona)'), findsOneWidget);
      expect(find.text('O Ouvinte'), findsOneWidget);
      expect(find.text('O Bibliotecário'), findsOneWidget);
      expect(find.text('O Anfitrião'), findsOneWidget);
      expect(find.text('O Artesão'), findsOneWidget);
    });

    testWidgets('Switching persona updates PersonaService', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(const SettingsPage()));
      await tester.pumpAndSettle();

      // Default persona is listener
      expect(PersonaService.instance.activePersona, AppPersona.listener);

      // Tap on Librarian
      await tester.tap(find.text('O Bibliotecário'));
      await tester.pumpAndSettle();

      expect(PersonaService.instance.activePersona, AppPersona.librarian);

      // Reset for safety
      PersonaService.instance.setPersona(AppPersona.listener);
    });
  });

  group('AppShell Persona Integration', () {
    testWidgets('AppShell shows Home navigation for Listener persona',
        (tester) async {
      PersonaService.instance.setPersona(AppPersona.listener);

      await tester.pumpWidget(createWidgetUnderTest(const AppShell()));
      await tester.pump();

      expect(find.text('Início'), findsAtLeastNWidgets(1));
      expect(find.text('Buscar'), findsAtLeastNWidgets(1));
    });

    testWidgets('AppShell shows Tags navigation for Librarian persona',
        (tester) async {
      PersonaService.instance.setPersona(AppPersona.librarian);

      await tester.pumpWidget(createWidgetUnderTest(const AppShell()));
      await tester.pump();

      expect(find.text('Tags'), findsAtLeastNWidgets(1));
      expect(find.text('Minhas Músicas'), findsAtLeastNWidgets(1));
      expect(find.text('Início'), findsNothing);
    });

    testWidgets('AppShell shows Disco and Karaoke for Host persona',
        (tester) async {
      PersonaService.instance.setPersona(AppPersona.host);

      await tester.pumpWidget(createWidgetUnderTest(const AppShell()));
      await tester.pump();

      expect(find.text('Disco'), findsAtLeastNWidgets(1));
      expect(find.text('Karaoke'), findsAtLeastNWidgets(1));
    });
  });
}
