import 'package:mocktail/mocktail.dart';
import 'dart:io';
import 'dart:async';
import 'package:music_tag_editor/services/auth_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/services/connectivity_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/security_service.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/lyrics_service.dart';
import 'package:music_tag_editor/services/local_duo_service.dart';
import 'package:music_tag_editor/services/equalizer_service.dart';
import 'package:music_tag_editor/services/firebase_sync_service.dart';
import 'package:music_tag_editor/services/persona_service.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:just_audio/just_audio.dart'; // Assuming this import is needed for AudioPlayer

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

class MockFirebaseSyncService extends Mock implements FirebaseSyncService {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

// Global mock instances for easy access
late MockAuthService mockAuth;
late MockDatabaseService mockDb;
late MockPlaybackService mockPlayback;
late MockSearchService mockSearch;
late MockDownloadService mockDownload;
late MockLocalDuoService mockDuo;
late MockConnectivityService mockConnectivity;
late MockThemeService mockTheme;
late MockAudioPlayer mockPlayer;
late MockDependencyManager mockDeps;

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
  PersonaService.resetInstance();

  // Create and inject standard mocks
  mockAuth = MockAuthService();
  mockDb = MockDatabaseService();
  mockPlayback = MockPlaybackService();
  mockSearch = MockSearchService();
  mockDownload = MockDownloadService();
  mockDuo = MockLocalDuoService();
  mockConnectivity = MockConnectivityService();
  mockTheme = MockThemeService();
  mockPlayer = MockAudioPlayer();
  mockDeps = MockDependencyManager();

  if (mockAuthInstance) AuthService.instance = mockAuth;
  if (mockDbInstance) DatabaseService.instance = mockDb;
  if (mockPlaybackInstance) PlaybackService.instance = mockPlayback;
  if (mockSearchInstance) SearchService.instance = mockSearch;
  if (mockDownloadInstance) DownloadService.instance = mockDownload;
  if (mockDuoInstance) LocalDuoService.instance = mockDuo;
  if (mockConnectivityInstance) ConnectivityService.instance = mockConnectivity;
  if (mockThemeInstance) ThemeService.instance = mockTheme;
  if (mockDepsInstance) DependencyManager.instance = mockDeps;

  // Default stubs to avoid common Null errors
  when(() => mockDb.getTracks(includeVault: any(named: 'includeVault')))
      .thenAnswer((_) async => []);
  when(() => mockDb.getRecentlyPlayed(limit: any(named: 'limit')))
      .thenAnswer((_) async => []);
  when(() => mockDb.saveSetting(any(), any())).thenAnswer((_) async => {});
  when(() => mockDb.getSetting(any())).thenAnswer((_) async => null);
  when(() => mockDb.loadCrossfadeDuration()).thenAnswer((_) async => 3);
  when(() => mockDb.getSpotifyCredentials())
      .thenAnswer((_) async => {'clientId': null, 'clientSecret': null});
  when(() => mockDb.getDownloadedUrls())
      .thenAnswer((_) async => <String, String?>{});
  when(() => mockPlayback.player)
      .thenReturn(mockPlayer); // Real player but usually fine
  when(() => mockPlayback.currentTrack).thenReturn(null);
  when(() => mockPlayback.queue).thenReturn([]);

  when(() => mockPlayer.playerStateStream).thenAnswer(
      (_) => Stream.value(PlayerState(false, ProcessingState.idle)));
  when(() => mockPlayer.positionStream)
      .thenAnswer((_) => Stream.value(Duration.zero));
  when(() => mockPlayer.bufferedPositionStream)
      .thenAnswer((_) => Stream.value(Duration.zero));
  when(() => mockPlayer.durationStream).thenAnswer((_) => Stream.value(null));
  when(() => mockPlayer.currentIndexStream)
      .thenAnswer((_) => Stream.value(null));
  when(() => mockPlayer.playingStream).thenAnswer((_) => Stream.value(false));
  when(() => mockPlayer.processingStateStream)
      .thenAnswer((_) => Stream.value(ProcessingState.idle));
  when(() => mockPlayer.volumeStream).thenAnswer((_) => Stream.value(1.0));
  when(() => mockPlayer.speedStream).thenAnswer((_) => Stream.value(1.0));
  when(() => mockPlayer.loopModeStream)
      .thenAnswer((_) => Stream.value(LoopMode.off));
  when(() => mockPlayer.shuffleModeEnabledStream)
      .thenAnswer((_) => Stream.value(false));
  when(() => mockPlayer.setVolume(any())).thenAnswer((_) async => {});

  when(() => mockDeps.ensureDependencies(onProgress: any(named: 'onProgress')))
      .thenAnswer((invocation) async {
    final callback = invocation.namedArguments[#onProgress] as void Function(
        String, double)?;
    callback?.call('Done', 1.0);
  });
  when(() => mockDeps.areAllDependenciesInstalled())
      .thenAnswer((_) async => true);

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
    _registerFallbackValueWasCalled = true;
  }
}

bool _registerFallbackValueWasCalled = false;
bool _sqfliteInitialized = false;

void setupHttpOverrides() {
  HttpOverrides.global = _MockHttpOverrides();
}

class _MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient extends Mock implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) => Future.value(_MockHttpClientRequest());

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) => Future.value(_MockHttpClientRequest());
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
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.fromIterable([
      [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
        0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
      ]
    ]).listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}
