import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:media_kit/media_kit.dart';
import 'test_helper.dart';
import 'package:music_hub/core/services/database_service.dart';
import 'package:music_hub/features/player/services/playback_service.dart';
import 'package:music_hub/core/services/theme_service.dart';
import 'package:music_hub/screens/home/home_screen.dart';
import 'package:music_hub/features/library/screens/mood_explorer_screen.dart';
import 'package:music_hub/features/library/screens/smart_library_screen.dart';
import 'package:music_hub/screens/stats/listening_stats_screen.dart';
import 'package:music_hub/features/party_mode/disco_mode_screen.dart';
import 'package:music_hub/features/discovery/services/search_service.dart';
import 'package:music_hub/features/discovery/services/download_service.dart';
import 'package:music_hub/core/services/dependency_manager.dart';
import 'package:music_hub/services/listening_stats_service.dart';
import 'package:music_hub/features/discovery/screens/search_screen.dart';
import 'package:music_hub/features/library/screens/local_sources_screen.dart';
import 'package:music_hub/features/library/screens/my_tracks_screen.dart';
import 'package:music_hub/features/library/services/metadata_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

class MockMetadataService extends Mock implements MetadataService {}

class MockPlaybackService extends Mock implements PlaybackService {}

class MockThemeService extends Mock implements ThemeService {}

class MockSearchService extends Mock implements SearchService {}

class MockDownloadService extends Mock implements DownloadService {}

class MockDependencyManager extends Mock implements DependencyManager {}

class MockListeningStatsService extends Mock implements ListeningStatsService {}

// MockAudioPlayer removed

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
  late MockPlayer mockPlayer;

  setUp(() {
    mockDb = MockDatabaseService();
    mockPlayback = MockPlaybackService();
    mockTheme = MockThemeService();
    mockSearch = MockSearchService();
    mockDownload = MockDownloadService();
    mockDeps = MockDependencyManager();
    mockStats = MockListeningStatsService();
    mockPlayer = MockPlayer();

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
    when(() => mockDb.getMusicFolders()).thenAnswer((_) async => []);

    when(() => mockTheme.primaryColor).thenReturn(Colors.blue);
    when(() => mockTheme.addListener(any())).thenReturn(null);
    when(() => mockTheme.removeListener(any())).thenReturn(null);

    when(() => mockPlayback.currentTrack).thenReturn(null);
    when(() => mockPlayback.currentTrackStream)
        .thenAnswer((_) => Stream.value(null));
    when(() => mockPlayback.player).thenReturn(mockPlayer);
    when(() => mockPlayer.stream)
        .thenReturn(FakePlayerStream()); // Wire up streams
    when(() => mockPlayer.state).thenReturn(const PlayerState());

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

  Widget createTestWidget(Widget child) =>
      MaterialApp(home: Scaffold(body: child));

  testWidgets('HomeView smoke test', (tester) async {
    await tester.pumpWidget(createTestWidget(const HomeScreen()));
    await tester.pump();
    expect(find.text('Início'), findsOneWidget);
  });

  testWidgets('MoodExplorerView smoke test', (tester) async {
    await tester.pumpWidget(createTestWidget(const MoodExplorerScreen()));
    await tester.pump();
    expect(find.text('Explorar por Humor'), findsOneWidget);
  });

  testWidgets('SmartLibraryView smoke test', (tester) async {
    await tester.pumpWidget(createTestWidget(const SmartLibraryScreen()));
    await tester.pump();
    expect(find.text('Top Hits'), findsOneWidget);
  });

  testWidgets('ListeningStatsView smoke test', (tester) async {
    await tester.pumpWidget(createTestWidget(const ListeningStatsScreen()));
    await tester.pump();
    await tester.pump();
    expect(find.text('Estatísticas de Escuta'), findsOneWidget);
  });

  testWidgets('DiscoModeView smoke test', (tester) async {
    await tester.pumpWidget(createTestWidget(const DiscoModeScreen()));
    await tester.pump();
    expect(find.text('Toque para sair'), findsOneWidget);
  });

  testWidgets('SearchPage smoke test', (tester) async {
    await tester.pumpWidget(createTestWidget(const SearchScreen()));
    await tester.pump();
    expect(find.text('Busca de Músicas'), findsOneWidget);
  });

// ... inside main ...
  testWidgets('LocalSourcesScreen smoke test', (tester) async {
    final mockMetadata = MockMetadataService();
    // Stub for getMusicFolders is in setup()
    await tester.pumpWidget(
        createTestWidget(LocalSourcesScreen(metadataService: mockMetadata)));
    await tester.pump();
    expect(find.text('Pastas de Música'), findsOneWidget);
  });

  testWidgets('MyTracksScreen smoke test', (tester) async {
    // Stub for getTracks is in setup()
    await tester.pumpWidget(createTestWidget(const MyTracksScreen()));
    await tester.pump(); // build
    await tester.pump(); // async load
    expect(find.text('Biblioteca'), findsOneWidget);
    expect(find.text('Músicas'), findsOneWidget);
    // Note: Video tab might be hidden/lazy loaded in some conditions or we can just verify one tab
  });
}
