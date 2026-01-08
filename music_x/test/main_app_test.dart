@Tags(['widget'])
library;

import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'test_helper.dart';
import 'package:music_hub/main.dart';
import 'package:music_hub/features/library/screens/library_screen.dart';
import 'package:music_hub/core/services/auth_service.dart';
import 'package:music_hub/core/services/database_service.dart';
import 'package:music_hub/core/services/theme_service.dart';
import 'package:music_hub/features/player/services/playback_service.dart';
import 'package:music_hub/core/services/connectivity_service.dart';
import 'package:music_hub/core/services/security_service.dart';
import 'package:music_hub/core/services/desktop_integration_service.dart';
import 'package:music_hub/core/services/dependency_manager.dart';
import 'package:music_hub/features/discovery/services/search_service.dart';
import 'package:music_hub/features/discovery/services/download_service.dart';
import 'package:music_hub/features/library/models/filename_format.dart';
import 'package:music_hub/features/core/screens/app_shell.dart';
import 'package:music_hub/features/core/login/login_screen.dart';

class MockAuthService extends Mock implements AuthService {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockThemeService extends Mock implements ThemeService {}

class MockPlaybackService extends Mock implements PlaybackService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockSecurityService extends Mock implements SecurityService {}

class MockDesktopIntegrationService extends Mock
    implements DesktopIntegrationService {}

class MockDependencyManager extends Mock implements DependencyManager {}

class MockSearchService extends Mock implements SearchService {}

class MockDownloadService extends Mock implements DownloadService {}

// MockAudioPlayer removed. Using MockPlayer from test_helper.dart or media_kit imports.

// Mock HTTP for NetworkImage
class MockHttpClient extends Mock implements HttpClient {}

class MockHttpClientRequest extends Mock implements HttpClientRequest {}

class MockHttpClientResponse extends Mock implements HttpClientResponse {}

class MockHttpHeaders extends Mock implements HttpHeaders {}

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = MockHttpClient();
    final request = MockHttpClientRequest();
    final response = MockHttpClientResponse();
    final headers = MockHttpHeaders();

    when(() => client.getUrl(any())).thenAnswer((_) async => request);
    when(() => request.headers).thenReturn(headers);
    when(() => request.close()).thenAnswer((_) async => response);
    when(() => response.statusCode).thenReturn(200);
    when(() => response.contentLength).thenReturn(_transparentImage.length);
    when(() => response.listen(any(),
        cancelOnError: any(named: 'cancelOnError'),
        onDone: any(named: 'onDone'),
        onError: any(named: 'onError'))).thenAnswer((invocation) {
      final onData =
          invocation.positionalArguments[0] as void Function(List<int>);
      final onDone = invocation.namedArguments[#onDone] as void Function()?;
      onData(_transparentImage);
      onDone?.call();
      return MockStreamSubscription<List<int>>();
    });
    return client;
  }
}

class MockStreamSubscription<T> extends Mock implements StreamSubscription<T> {
  @override
  Future<void> cancel() async {}
}

final List<int> _transparentImage = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

void main() {
  HttpOverrides.global = _MockHttpOverrides();

  late MockAuthService mockAuth;
  late MockDatabaseService mockDb;
  late MockThemeService mockTheme;
  late MockPlaybackService mockPlayback;
  late MockConnectivityService mockConnectivity;
  late MockSecurityService mockSecurity;
  late MockDesktopIntegrationService mockDesktop;
  late MockDependencyManager mockDeps;
  late MockSearchService mockSearch;
  late MockDownloadService mockDownload;
  late MockPlayer mockPlayer;

  setUp(() {
    mockAuth = MockAuthService();
    mockDb = MockDatabaseService();
    mockTheme = MockThemeService();
    mockPlayback = MockPlaybackService();
    mockConnectivity = MockConnectivityService();
    mockSecurity = MockSecurityService();
    mockDesktop = MockDesktopIntegrationService();
    mockDeps = MockDependencyManager();
    mockSearch = MockSearchService();
    mockDownload = MockDownloadService();
    mockPlayer = MockPlayer();

    AuthService.instance = mockAuth;
    DatabaseService.instance = mockDb;
    ThemeService.instance = mockTheme;
    PlaybackService.instance = mockPlayback;
    ConnectivityService.instance = mockConnectivity;
    SecurityService.instance = mockSecurity;
    DesktopIntegrationService.instance = mockDesktop;
    DependencyManager.instance = mockDeps;
    SearchService.instance = mockSearch;
    DownloadService.instance = mockDownload;

    when(() => mockAuth.isAuthenticated).thenReturn(false);
    when(() => mockTheme.primaryColor).thenReturn(Colors.blue);
    when(() => mockTheme.addListener(any())).thenReturn(null);
    when(() => mockTheme.removeListener(any())).thenReturn(null);

    when(() => mockPlayback.player).thenReturn(mockPlayer);
    when(() => mockPlayer.playerStateStream).thenAnswer(
        (_) => Stream.value(PlayerState(false, ProcessingState.idle)));
    when(() => mockPlayer.positionStream)
        .thenAnswer((_) => Stream.value(Duration.zero));
    when(() => mockPlayer.bufferedPositionStream)
        .thenAnswer((_) => Stream.value(Duration.zero));
    when(() => mockPlayer.playingStream).thenAnswer((_) => Stream.value(false));
    when(() => mockPlayer.durationStream).thenAnswer((_) => Stream.value(null));
    when(() => mockPlayer.sequenceStateStream)
        .thenAnswer((_) => const Stream.empty());

    when(() => mockPlayer.position).thenReturn(Duration.zero);
    when(() => mockPlayer.bufferedPosition).thenReturn(Duration.zero);
    when(() => mockPlayer.duration).thenReturn(null);
    when(() => mockPlayer.volume).thenReturn(1.0);
    when(() => mockPlayer.speed).thenReturn(1.0);
    when(() => mockPlayer.loopMode).thenReturn(LoopMode.off);
    when(() => mockPlayer.shuffleModeEnabled).thenReturn(false);
    when(() => mockPlayer.processingState).thenReturn(ProcessingState.idle);
    when(() => mockPlayer.playing).thenReturn(false);

    when(() => mockPlayback.currentTrack).thenReturn(null);
    when(() => mockPlayback.currentTrackStream)
        .thenAnswer((_) => const Stream.empty());

    when(() => mockConnectivity.isOffline).thenReturn(ValueNotifier(false));

    when(() =>
            mockDeps.ensureDependencies(onProgress: any(named: 'onProgress')))
        .thenAnswer((_) async {});

    when(() => mockDeps.client).thenReturn(MockClient((request) async {
      return http.Response('{}', 200);
    }));

    when(() => mockDb.getAllTracks()).thenAnswer((_) async => []);
  });

  testWidgets('MusicHubApp shows AppShell when not authenticated (Guest Mode)',
      (tester) async {
    when(() => mockDb.loadFilenameFormat())
        .thenAnswer((_) async => FilenameFormat.artistTitle);
    when(() => mockDb.getTracks()).thenAnswer((_) async => []);
    when(() => mockDb.getPlaylists()).thenAnswer((_) async => []);

    await tester.pumpWidget(const MusicHubApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('MusicHubApp shows AppShell when authenticated', (tester) async {
    when(() => mockAuth.isAuthenticated).thenReturn(true);

    // Stubbing for AppShell and its sub-widgets
    when(() => mockDb.loadFilenameFormat())
        .thenAnswer((_) async => FilenameFormat.artistTitle);
    when(() => mockDb.getTracks()).thenAnswer((_) async => []);
    when(() => mockDb.getPlaylists()).thenAnswer((_) async => []);

    await tester.pumpWidget(const MusicHubApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('LibraryScreen displays initial empty state', (tester) async {
    when(() => mockDb.loadFilenameFormat())
        .thenAnswer((_) async => FilenameFormat.artistTitle);

    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const LibraryScreen()));
    await tester.pump();

    expect(find.text('Nenhuma pasta selecionada.'), findsOneWidget);
    expect(find.text('Selecionar Pasta'), findsOneWidget);
  });

  group('FilenameFormat functional tests', () {
    test('artistTitle format', () {
      const format = FilenameFormat.artistTitle;
      final result = format.generateFilename(
        artist: 'Artist',
        title: 'Title',
        trackNumber: 1,
      );
      expect(result, 'Artist - Title');
    });

    test('titleArtist format', () {
      const format = FilenameFormat.titleArtist;
      final result = format.generateFilename(
        artist: 'Artist',
        title: 'Title',
        trackNumber: 1,
      );
      expect(result, 'Title (Artist)');
    });

    test('trackArtistTitle format', () {
      const format = FilenameFormat.trackArtistTitle;
      final result = format.generateFilename(
        artist: 'Artist',
        title: 'Title',
        trackNumber: 5,
      );
      expect(result, '05. Artist - Title');
    });
  });
}
// IGNORE_TESTS_TEMPORARILY
