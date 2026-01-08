import 'package:mocktail/mocktail.dart';
import 'dart:io';
import 'dart:async';
import 'package:music_hub/core/services/auth_service.dart';
import 'package:music_hub/core/services/database_service.dart';
import 'package:music_hub/core/services/theme_service.dart';
import 'package:music_hub/core/services/connectivity_service.dart';
import 'package:music_hub/features/player/services/playback_service.dart';
import 'package:music_hub/core/services/security_service.dart';
import 'package:music_hub/core/services/dependency_manager.dart';
import 'package:music_hub/features/discovery/services/search_service.dart';
import 'package:music_hub/features/discovery/services/download_service.dart';
import 'package:music_hub/features/player/services/lyrics_service.dart';
import 'package:music_hub/core/services/local_duo_service.dart';
import 'package:music_hub/features/library/models/search_models.dart';
import 'package:music_hub/features/player/services/equalizer_service.dart';
import 'package:music_hub/core/services/global_navigation_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:music_hub/features/library/services/metadata_aggregator_service.dart';
import 'package:music_hub/features/library/models/metadata_models.dart';

Future<void> setupSqflite() async {
  if (!_sqfliteInitialized) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _sqfliteInitialized = true;
  }
}

class MockAuthService extends Mock implements AuthService {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockThemeService extends Mock implements ThemeService {}

class MockConnectivityService extends Mock implements ConnectivityService {}

class MockPlaybackService extends Mock implements PlaybackService {}

class MockSecurityService extends Mock implements SecurityService {}

class MockDependencyManager extends Mock implements DependencyManager {}

class MockSearchService extends Mock implements SearchService {}

class MockDownloadService extends Mock implements DownloadService {}

class MockLyricsService extends Mock implements LyricsService {}

class MockLocalDuoService extends Mock implements LocalDuoService {}

class MockEqualizerService extends Mock implements EqualizerService {}

class MockPlayer extends Mock implements AudioPlayer {}

class MockMetadataAggregatorService extends Mock
    implements MetadataAggregatorService {}

// Global mock instances for easy access
late MockAuthService mockAuth;
late MockDatabaseService mockDb;
late MockPlaybackService mockPlayback;
late MockSearchService mockSearch;
late MockDownloadService mockDownload;
late MockLocalDuoService mockDuo;
late MockConnectivityService mockConnectivity;
late MockThemeService mockTheme;
late MockPlayer mockPlayer;
late MockDependencyManager mockDeps;
late MockLyricsService mockLyrics;
late MockEqualizerService mockEqualizer;
late MockMetadataAggregatorService mockMetadataAggregator;

Future<void> setupMusicTest({
  bool mockAuthInstance = true,
  bool mockDbInstance = true,
  bool mockPlaybackInstance = true,
  bool mockSearchInstance = true,
  bool mockDownloadInstance = true,
  bool mockDuoInstance = true,
  bool mockConnectivityInstance = true,
  bool mockThemeInstance = true,
  bool mockDepsInstance = true,
}) async {
  // Mock all HTTP requests in tests
  HttpOverrides.global = _MockHttpOverrides();

  if (!_registerFallbackValueWasCalled) {
    registerFallbackValue(Uri.parse('http://test.com'));
    registerFallbackValue(const Color(0xFF000000));
    registerFallbackValue(Duration.zero);
    registerFallbackValue(SearchResult(
      id: 'fallback',
      title: 'Fallback',
      artist: 'Fallback',
      url: 'http://fallback',
      platform: MediaPlatform.youtube,
    ));
    registerFallbackValue(MediaPlatform.youtube);
    registerFallbackValue(LoopMode.off);
    registerFallbackValue(AudioSource.uri(Uri.parse('http://test.com')));
    _registerFallbackValueWasCalled = true;
  }

  // Reset ALL core singletons
  AuthService.resetInstance();
  DatabaseService.resetInstance();
  PlaybackService.resetInstance();
  SearchService.resetInstance();
  DownloadService.resetInstance();
  LyricsService.resetInstance();
  LocalDuoService.resetInstance();
  ConnectivityService.resetInstance();
  ThemeService.resetInstance();
  DependencyManager.resetInstance();
  GlobalNavigationService.resetInstance();

  // Create and inject standard mocks
  mockAuth = MockAuthService();
  mockDb = MockDatabaseService();
  mockPlayback = MockPlaybackService();
  mockSearch = MockSearchService();
  mockDownload = MockDownloadService();
  mockDuo = MockLocalDuoService();
  mockConnectivity = MockConnectivityService();
  mockTheme = MockThemeService();
  mockPlayer = MockPlayer();
  mockDeps = MockDependencyManager();
  mockLyrics = MockLyricsService();
  mockPlayer = MockPlayer();
  mockDeps = MockDependencyManager();
  mockLyrics = MockLyricsService();
  mockEqualizer = MockEqualizerService();
  mockMetadataAggregator = MockMetadataAggregatorService();

  if (mockAuthInstance) AuthService.instance = mockAuth;
  if (mockDbInstance) DatabaseService.instance = mockDb;
  if (mockPlaybackInstance) PlaybackService.instance = mockPlayback;
  if (mockSearchInstance) SearchService.instance = mockSearch;
  if (mockDownloadInstance) DownloadService.instance = mockDownload;
  if (mockDuoInstance) LocalDuoService.instance = mockDuo;
  if (mockConnectivityInstance) ConnectivityService.instance = mockConnectivity;
  if (mockThemeInstance) ThemeService.instance = mockTheme;
  if (mockDepsInstance) DependencyManager.instance = mockDeps;
  LyricsService.instance = mockLyrics;
  LyricsService.instance = mockLyrics;
  EqualizerService.instance = mockEqualizer;
  MetadataAggregatorService.instance = mockMetadataAggregator;

  // Default stubs to avoid common Null errors
  when(() => mockDb.getTracks(includeVault: any(named: 'includeVault')))
      .thenAnswer((_) async => []);
  when(() => mockDb.getRecentlyPlayed(limit: any(named: 'limit')))
      .thenAnswer((_) async => []);
  when(() => mockMetadataAggregator.aggregateMetadata(
        any(),
        any(),
        durationMs: any(named: 'durationMs'),
      )).thenAnswer((_) async => AggregatedMetadata());
  when(() => mockDb.saveSetting(any(), any())).thenAnswer((_) async {});
  when(() => mockDb.getSetting(any())).thenAnswer((_) async => null);
  when(() => mockDb.checkpoint()).thenAnswer((_) async {});
  when(() => mockDb.loadCrossfadeDuration()).thenAnswer((_) async => 3);
  // Removed getSpotifyCredentials stub as it's no longer used
  when(() => mockDb.getDownloadedUrls())
      .thenAnswer((_) async => <String, String?>{});
  when(() => mockPlayback.player)
      .thenReturn(mockPlayer); // Real player but usually fine
  when(() => mockPlayback.currentTrack).thenReturn(null);
  when(() => mockPlayback.currentTrackStream)
      .thenAnswer((_) => Stream.value(null));
  when(() => mockDb.getAllTracks()).thenAnswer((_) async => []);
  when(() => mockPlayback.sleepTimerStream)
      .thenAnswer((_) => Stream.value(null));
  when(() => mockPlayback.lyricsStream).thenAnswer((_) => Stream.value([]));
  when(() => mockDb.getMusicFolders()).thenAnswer((_) async => []);
  when(() => mockDb.addMusicFolder(any())).thenAnswer((_) async {});
  when(() => mockDb.removeMusicFolder(any()))
      .thenAnswer((_) async {}); // Added remove mock
  when(() => mockPlayback.queue).thenReturn([]);

  when(() => mockTheme.updateThemeFromImage(any())).thenAnswer((_) async {});
  when(() => mockTheme.primaryColor).thenReturn(const Color(0xFF000000));
  when(() => mockEqualizer.applyPresetForGenre(any())).thenAnswer((_) async {});
  when(() => mockEqualizer.calculateNormalizedVolume(any())).thenReturn(1.0);
  when(() => mockEqualizer.isAutoMode).thenReturn(false);
  when(() => mockLyrics.fetchLyrics(any(), any())).thenAnswer((_) async => []);
  when(() => mockDuo.sendMessage(any())).thenAnswer((_) async {});
  when(() => mockDb.trackPlay(any())).thenAnswer((_) async {});
  when(() => mockDb.saveTrack(any())).thenAnswer((_) async {});
  when(() => mockDb.toggleVault(any(), any())).thenAnswer((_) async {});
  when(() => mockDb.updateTrackMetadata(any(), any(), any(), any()))
      .thenAnswer((_) async {});
  when(() => mockDb.savePlaylist(any())).thenAnswer((_) async {});
  when(() => mockDb.addTrackToPlaylist(any(), any())).thenAnswer((_) async {});
  when(() => mockDb.deleteTrack(any())).thenAnswer((_) async {});
  when(() => mockDb.saveGuest(any(), any())).thenAnswer((_) async {});
  when(() => mockDb.addTrackToDuoSession(any(), any()))
      .thenAnswer((_) async {});

  // Fixed signature for getStreamUrl
  when(() => mockSearch.getStreamUrl(
        any(),
        platform: any(named: 'platform'),
      )).thenAnswer((_) async => null);
  when(() => mockSearch.getFormats(any(), any())).thenAnswer((_) async => []);
  when(() => mockDuo.role).thenReturn(DuoRole.none);

  // Wire up MockPlayer properties
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

  // Note: No need to stub mockPlayerStreams getters as they are now real implementation

  when(() => mockPlayer.setVolume(any())).thenAnswer((_) async {});
  when(() => mockPlayer.play()).thenAnswer((_) async {});
  when(() => mockPlayer.pause()).thenAnswer((_) async {});
  when(() => mockPlayer.stop()).thenAnswer((_) async {});
  when(() => mockPlayer.seek(any())).thenAnswer((_) async {});
  when(() => mockPlayer.setAudioSource(any(),
      initialPosition: any(named: 'initialPosition'),
      preload: any(named: 'preload'))).thenAnswer((_) async => null);
  when(() => mockPlayer.setLoopMode(any())).thenAnswer((_) async {});
  when(() => mockPlayer.setShuffleModeEnabled(any())).thenAnswer((_) async {});

  when(() => mockDeps.ensureDependencies(onProgress: any(named: 'onProgress')))
      .thenAnswer((invocation) async {
    final callback = invocation.namedArguments[#onProgress] as void Function(
        String, double)?;
    callback?.call('Done', 1.0);
  });
  when(() => mockDeps.areAllDependenciesInstalled())
      .thenAnswer((_) async => true);
  when(() => mockDeps.client).thenReturn(MockClient((request) async {
    return http.Response('{}', 200);
  }));
}

bool _registerFallbackValueWasCalled = false;
bool _sqfliteInitialized = false;

void setupHttpOverrides() {
  HttpOverrides.global = _MockHttpOverrides();
}

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient extends Mock implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) =>
      Future.value(_MockHttpClientRequest());

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      Future.value(_MockHttpClientRequest());
}

class _MockHttpClientRequest extends Mock implements HttpClientRequest {
  @override
  HttpHeaders get headers => MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() => Future.value(_MockHttpClientResponse());

  @override
  Future<void> addStream(Stream<List<int>> stream) async {}
}

class MockHttpHeaders extends Mock implements HttpHeaders {
  @override
  void forEach(void Function(String name, List<String> values) action) {
    // No-op for empty headers or implementation if needed
  }
}

class _MockHttpClientResponse extends Mock implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => 3;

  @override
  HttpHeaders get headers => MockHttpHeaders();

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => 'OK';

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      Stream<List<int>>.fromIterable([
        [
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82
        ]
      ]).listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);
}
