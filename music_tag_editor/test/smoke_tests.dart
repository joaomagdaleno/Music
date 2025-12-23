import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/views/home_view.dart';
import 'package:music_tag_editor/views/mood_explorer_view.dart';
import 'package:music_tag_editor/views/smart_library_view.dart';
import 'package:music_tag_editor/views/listening_stats_view.dart';
import 'package:music_tag_editor/views/disco_mode_view.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:music_tag_editor/services/listening_stats_service.dart';
import 'package:music_tag_editor/views/search_page.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

class MockPlaybackService extends Mock implements PlaybackService {}

class MockThemeService extends Mock implements ThemeService {}

class MockSearchService extends Mock implements SearchService {}

class MockDownloadService extends Mock implements DownloadService {}

class MockDependencyManager extends Mock implements DependencyManager {}

class MockListeningStatsService extends Mock implements ListeningStatsService {}

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

  late MockDatabaseService mockDb;
  late MockPlaybackService mockPlayback;
  late MockThemeService mockTheme;
  late MockSearchService mockSearch;
  late MockDownloadService mockDownload;
  late MockDependencyManager mockDeps;
  late MockListeningStatsService mockStats;
  late MockAudioPlayer mockAudioPlayer;

  setUp(() {
    mockDb = MockDatabaseService();
    mockPlayback = MockPlaybackService();
    mockTheme = MockThemeService();
    mockSearch = MockSearchService();
    mockDownload = MockDownloadService();
    mockDeps = MockDependencyManager();
    mockStats = MockListeningStatsService();
    mockAudioPlayer = MockAudioPlayer();

    DatabaseService.instance = mockDb;
    PlaybackService.instance = mockPlayback;
    ThemeService.instance = mockTheme;
    SearchService.instance = mockSearch;
    DownloadService.instance = mockDownload;
    DependencyManager.instance = mockDeps;
    ListeningStatsService.instance = mockStats;

    when(() => mockDb.getTracks()).thenAnswer((_) async => []);
    when(() => mockDb.getRecentlyPlayed(limit: any(named: 'limit')))
        .thenAnswer((_) async => []);
    when(() => mockDb.getMostPlayed(limit: any(named: 'limit')))
        .thenAnswer((_) async => []);
    when(() => mockDb.getPlayHistory()).thenAnswer((_) async => []);
    when(() => mockDb.getPlaylists()).thenAnswer((_) async => []);
    when(() => mockDb.getLearningRules()).thenAnswer((_) async => []);
    when(() => mockDb.getTracksByMood(any())).thenAnswer((_) async => []);

    when(() => mockTheme.primaryColor).thenReturn(Colors.blue);
    when(() => mockTheme.addListener(any())).thenReturn(null);
    when(() => mockTheme.removeListener(any())).thenReturn(null);

    when(() => mockPlayback.currentTrack).thenReturn(null);
    when(() => mockPlayback.player).thenReturn(mockAudioPlayer);
    when(() => mockAudioPlayer.playerStateStream)
        .thenAnswer((_) => const Stream.empty());

    when(() =>
            mockDeps.ensureDependencies(onProgress: any(named: 'onProgress')))
        .thenAnswer((_) async {});

    when(() => mockStats.getStats()).thenAnswer((_) async => ListeningStats(
          totalTracks: 0,
          totalPlays: 0,
          estimatedListeningTime: Duration.zero,
          topTracks: [],
          topArtists: [],
          topGenres: [],
        ));
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('HomeView smoke test', (tester) async {
    await tester.pumpWidget(createTestWidget(const HomeView()));
    await tester.pump();
    expect(find.text('Início'), findsOneWidget);
  });

  testWidgets('MoodExplorerView smoke test', (tester) async {
    await tester.pumpWidget(createTestWidget(MoodExplorerView()));
    await tester.pump();
    expect(find.text('Qual o seu mood hoje?'), findsOneWidget);
  });

  testWidgets('SmartLibraryView smoke test', (tester) async {
    await tester.pumpWidget(createTestWidget(const SmartLibraryView()));
    await tester.pump();
    expect(find.text('Top Hits'), findsOneWidget);
  });

  testWidgets('ListeningStatsView smoke test', (tester) async {
    await tester.pumpWidget(createTestWidget(const ListeningStatsView()));
    await tester.pump();
    await tester.pump();
    expect(find.text('Suas Estatísticas'), findsOneWidget);
  });

  testWidgets('DiscoModeView smoke test', (tester) async {
    await tester.pumpWidget(createTestWidget(const DiscoModeView()));
    await tester.pump();
    expect(find.text('Toque para sair'), findsOneWidget);
  });

  testWidgets('SearchPage smoke test', (tester) async {
    await tester.pumpWidget(createTestWidget(const SearchPage()));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Busca de Músicas'), findsOneWidget);
  });
}
