import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_tag_editor/main.dart';
import 'package:music_tag_editor/services/auth_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/connectivity_service.dart';
import 'package:music_tag_editor/services/security_service.dart';
import 'package:music_tag_editor/services/desktop_integration_service.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/views/settings_page.dart';
import 'package:music_tag_editor/views/app_shell.dart';
import 'package:music_tag_editor/views/login_page.dart';

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

class MockAudioPlayer extends Mock implements AudioPlayer {}

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
  late MockAudioPlayer mockAudioPlayer;

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
    mockAudioPlayer = MockAudioPlayer();

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

    when(() => mockPlayback.player).thenReturn(mockAudioPlayer);
    when(() => mockPlayback.currentTrack).thenReturn(null);
    when(() => mockAudioPlayer.playerStateStream)
        .thenAnswer((_) => const Stream.empty());

    when(() =>
            mockDeps.ensureDependencies(onProgress: any(named: 'onProgress')))
        .thenAnswer((_) async {});
  });

  testWidgets('MusicTagEditorApp shows LoginPage when not authenticated',
      (tester) async {
    await tester.pumpWidget(const MusicTagEditorApp());
    await tester.pump();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(AppShell), findsNothing);
  });

  testWidgets('MusicTagEditorApp shows AppShell when authenticated',
      (tester) async {
    when(() => mockAuth.isAuthenticated).thenReturn(true);

    // Stubbing for AppShell and its sub-widgets
    when(() => mockConnectivity.isOffline).thenReturn(ValueNotifier(false));
    when(() => mockDb.loadFilenameFormat())
        .thenAnswer((_) async => FilenameFormat.artistTitle);
    when(() => mockDb.getTracks()).thenAnswer((_) async => []);
    when(() => mockDb.getPlaylists()).thenAnswer((_) async => []);

    await tester.pumpWidget(const MusicTagEditorApp());
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('LibraryPage displays initial empty state', (tester) async {
    when(() => mockDb.loadFilenameFormat())
        .thenAnswer((_) async => FilenameFormat.artistTitle);

    await tester.pumpWidget(
        const MaterialApp(home: LibraryPage(title: 'Test Library')));
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
