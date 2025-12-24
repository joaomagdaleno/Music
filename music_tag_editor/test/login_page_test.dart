@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/views/login_page.dart';
import 'package:music_tag_editor/services/auth_service.dart';

import 'package:music_tag_editor/services/connectivity_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:just_audio/just_audio.dart';

import 'package:music_tag_editor/services/security_service.dart';
import 'package:music_tag_editor/services/equalizer_service.dart';
import 'package:music_tag_editor/services/desktop_integration_service.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/firebase_sync_service.dart';
import 'package:music_tag_editor/services/local_duo_service.dart';
import 'package:music_tag_editor/services/lyrics_service.dart';

class MockAuthService extends Mock implements AuthService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockPlaybackService extends Mock implements PlaybackService {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockThemeService extends Mock implements ThemeService {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockSecurityService extends Mock implements SecurityService {}

class MockEqualizerService extends Mock implements EqualizerService {}

class MockDesktopIntegrationService extends Mock
    implements DesktopIntegrationService {}

class MockAndroidEqualizer extends Mock implements AndroidEqualizer {}

class MockDependencyManager extends Mock implements DependencyManager {}

class MockSearchService extends Mock implements SearchService {}

class MockDownloadService extends Mock implements DownloadService {}

class MockFirebaseSyncService extends Mock implements FirebaseSyncService {}

class MockLocalDuoService extends Mock implements LocalDuoService {}

class MockLyricsService extends Mock implements LyricsService {}

void main() {
  late MockAuthService mockAuth;
  late MockConnectivityService mockConnectivity;
  late MockPlaybackService mockPlayback;
  late MockDatabaseService mockDb;
  late MockThemeService mockTheme;
  late MockAudioPlayer mockPlayer;
  late MockSecurityService mockSecurity;
  late MockEqualizerService mockEqualizer;
  late MockDesktopIntegrationService mockDesktop;
  late MockAndroidEqualizer mockAndroidEqualizer;
  late MockDependencyManager mockDeps;
  late MockSearchService mockSearch;
  late MockDownloadService mockDownload;
  late MockFirebaseSyncService mockSync;
  late MockLocalDuoService mockDuo;
  late MockLyricsService mockLyrics;

  setUp(() {
    mockAuth = MockAuthService();
    mockConnectivity = MockConnectivityService();
    mockPlayback = MockPlaybackService();
    mockDb = MockDatabaseService();
    mockTheme = MockThemeService();
    mockPlayer = MockAudioPlayer();
    mockSecurity = MockSecurityService();
    mockEqualizer = MockEqualizerService();
    mockDesktop = MockDesktopIntegrationService();
    mockAndroidEqualizer = MockAndroidEqualizer();
    mockDeps = MockDependencyManager();
    mockSearch = MockSearchService();
    mockDownload = MockDownloadService();
    mockSync = MockFirebaseSyncService();
    mockDuo = MockLocalDuoService();
    mockLyrics = MockLyricsService();

    AuthService.instance = mockAuth;
    ConnectivityService.instance = mockConnectivity;
    PlaybackService.instance = mockPlayback;
    DatabaseService.instance = mockDb;
    ThemeService.instance = mockTheme;
    SecurityService.instance = mockSecurity;
    EqualizerService.instance = mockEqualizer;
    DesktopIntegrationService.instance = mockDesktop;
    DependencyManager.instance = mockDeps;
    SearchService.instance = mockSearch;
    DownloadService.instance = mockDownload;
    FirebaseSyncService.instance = mockSync;
    LocalDuoService.instance = mockDuo;
    LyricsService.instance = mockLyrics;

    final isOffline = ValueNotifier<bool>(false);
    when(() => mockConnectivity.isOffline).thenReturn(isOffline);
    when(() => mockPlayback.player).thenReturn(mockPlayer);
    when(() => mockPlayback.currentTrack).thenReturn(null);
    when(() => mockPlayer.playerStateStream).thenAnswer(
        (_) => Stream.value(PlayerState(false, ProcessingState.idle)));
    when(() => mockPlayer.currentIndexStream)
        .thenAnswer((_) => Stream.value(null));
    when(() => mockPlayer.processingStateStream)
        .thenAnswer((_) => Stream.value(ProcessingState.idle));
    when(() => mockPlayer.playingStream).thenAnswer((_) => Stream.value(false));
    when(() => mockPlayer.positionStream)
        .thenAnswer((_) => Stream.value(Duration.zero));
    when(() => mockEqualizer.equalizer).thenReturn(mockAndroidEqualizer);
    when(() =>
            mockDeps.ensureDependencies(onProgress: any(named: 'onProgress')))
        .thenAnswer((_) async => {});
    when(() => mockDuo.role).thenReturn(DuoRole.none);
    when(() => mockDb.getTracks()).thenAnswer((_) async => []);
    when(() => mockDb.getPlaylists()).thenAnswer((_) async => []);

    when(() => mockAuth.login(any(), any())).thenAnswer((_) async => true);
    when(() => mockAuth.register(any(), any())).thenAnswer((_) async => true);
  });

  Widget createTestWidget() {
    return const MaterialApp(home: LoginPage());
  }

  group('LoginPage', () {
    testWidgets('renders Scaffold', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('has email and password fields', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
    });

    testWidgets('has login button', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('can toggle to register mode', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.textContaining('Não tem conta?'));
      await tester.pump();

      expect(find.text('Criar Conta'), findsWidgets);
      expect(find.text('Cadastrar'), findsOneWidget);
    });

    testWidgets('calls login on button press', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final emailField = find.byKey(const Key('email_field'));
      final passwordField = find.byKey(const Key('password_field'));

      await tester.enterText(emailField, 'test@test.com');
      await tester.enterText(passwordField, 'password');
      await tester.tap(find.text('Entrar'));
      await tester.pump(const Duration(milliseconds: 200));

      verify(() => mockAuth.login('test@test.com', 'password')).called(1);
    });
  });
}
