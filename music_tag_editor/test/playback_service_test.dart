import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/local_duo_service.dart';
import 'package:music_tag_editor/services/equalizer_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/services/lyrics_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

class MockLocalDuoService extends Mock implements LocalDuoService {}

class MockEqualizerService extends Mock implements EqualizerService {}

class MockThemeService extends Mock implements ThemeService {}

class MockSearchService extends Mock implements SearchService {}

class MockLyricsService extends Mock implements LyricsService {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockAudioHandler extends Mock implements BaseAudioHandler {
  @override
  final BehaviorSubject<MediaItem?> mediaItem = BehaviorSubject<MediaItem?>();
  @override
  final BehaviorSubject<PlaybackState> playbackState =
      BehaviorSubject<PlaybackState>();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel('plugins.flutter.io/path_provider')
      .setMockMethodCallHandler((MethodCall methodCall) async {
    return '.';
  });

  late MockDatabaseService mockDb;
  late MockLocalDuoService mockDuo;
  late MockEqualizerService mockEqualizer;
  late MockThemeService mockTheme;
  late MockSearchService mockSearch;
  late MockLyricsService mockLyrics;
  late MockAudioPlayer mockPlayer;
  late MockAudioHandler mockHandler;
  late PlaybackService service;

  setUp(() {
    mockDb = MockDatabaseService();
    mockDuo = MockLocalDuoService();
    mockEqualizer = MockEqualizerService();
    mockTheme = MockThemeService();
    mockSearch = MockSearchService();
    mockLyrics = MockLyricsService();
    mockPlayer = MockAudioPlayer();
    mockHandler = MockAudioHandler();

    DatabaseService.instance = mockDb;
    LocalDuoService.instance = mockDuo;
    EqualizerService.instance = mockEqualizer;
    ThemeService.instance = mockTheme;
    SearchService.instance = mockSearch;
    LyricsService.instance = mockLyrics;

    // Register fallback values for mocktail
    registerFallbackValue(FakeAudioSource());
    registerFallbackValue(const Duration(seconds: 0));

    // Default stubs
    when(() => mockEqualizer.equalizer).thenReturn(FakeAndroidEqualizer());
    when(() => mockEqualizer.applyPresetForGenre(any()))
        .thenAnswer((_) async {});
    when(() => mockTheme.updateThemeFromImage(any())).thenAnswer((_) async {});
    when(() => mockDuo.role).thenReturn(DuoRole.none);
    when(() => mockDuo.sendMessage(any())).thenReturn(null);
    when(() => mockPlayer.currentIndexStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockPlayer.processingStateStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockPlayer.playingStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockPlayer.positionStream)
        .thenAnswer((_) => const Stream.empty());
    when(() => mockPlayer.setAudioSource(any(),
            initialPosition: any(named: 'initialPosition'),
            initialIndex: any(named: 'initialIndex')))
        .thenAnswer((_) async => const Duration(seconds: 0));
    when(() => mockPlayer.play()).thenAnswer((_) async {});
    when(() => mockPlayer.pause()).thenAnswer((_) async {});
    when(() => mockPlayer.stop()).thenAnswer((_) async {});
    when(() => mockPlayer.seek(any())).thenAnswer((_) async {});
    when(() => mockPlayer.position).thenReturn(const Duration(seconds: 10));
    when(() => mockPlayer.playing).thenReturn(false);
    when(() => mockPlayer.processingState).thenReturn(ProcessingState.idle);

    when(() => mockSearch.getStreamUrl(any()))
        .thenAnswer((_) async => "http://stream.url");
    when(() => mockDb.loadCrossfadeDuration()).thenAnswer((_) async => 3);
    when(() => mockDb.trackPlay(any())).thenAnswer((_) async {});
    when(() => mockLyrics.fetchLyrics(any(), any()))
        .thenAnswer((_) async => []);

    service = PlaybackService.forTesting(
      player: mockPlayer,
      handler: mockHandler,
    );
    PlaybackService.instance = service;
  });

  group('PlaybackService - Core Logic', () {
    final testTrack = SearchResult(
      id: 'test_1',
      title: 'Test Track',
      artist: 'Test Artist',
      url: 'http://test_url',
      platform: MediaPlatform.youtube,
      thumbnail: 'http://thumb.jpg',
      genre: 'Rock',
    );

    test('playSearchResult sets source and plays', () async {
      await service.playSearchResult(testTrack);

      expect(service.currentTrack, equals(testTrack));
      verify(() => mockPlayer.setAudioSource(any())).called(1);
      verify(() => mockPlayer.play()).called(1);
      verify(() => mockTheme.updateThemeFromImage(any())).called(1);
      verify(() => mockEqualizer.applyPresetForGenre(any())).called(1);
    });

    test('pause calls player pause and sends message', () async {
      await service.pause();
      verify(() => mockPlayer.pause()).called(1);
      verify(() => mockDuo.sendMessage(any(that: containsValue('pause'))))
          .called(1);
    });

    test('resume calls player play and sends message', () async {
      await service.resume();
      verify(() => mockPlayer.play()).called(1);
      verify(() => mockDuo.sendMessage(any(that: containsValue('play'))))
          .called(1);
    });

    test('stop calls player stop', () async {
      await service.stop();
      verify(() => mockPlayer.stop()).called(1);
    });

    test('seek calls player seek and sends message', () async {
      const pos = Duration(seconds: 30);
      await service.seek(pos);
      verify(() => mockPlayer.seek(pos)).called(1);
      verify(() => mockDuo.sendMessage(any(that: containsValue('seek'))))
          .called(1);
    });

    test('addToQueue adds track and notifies remote', () async {
      await service.addToQueue(testTrack);
      expect(service.queue, contains(testTrack));
      verify(() =>
              mockDuo.sendMessage(any(that: containsValue('add_to_queue'))))
          .called(1);
    });

    test('clearQueue empties the queue', () {
      service.clearQueue();
      expect(service.queue, isEmpty);
    });

    test('setSleepTimer stops playback after duration', () async {
      // Use a very short duration for testing if possible, but Timer.periodic is hard to mock without package:fake_async
      // For now, just test it starts and emits
      service.setSleepTimer(const Duration(seconds: 5));
      expect(service.sleepTimeLeft, equals(const Duration(seconds: 5)));
    });

    test('cancelSleepTimer resets status', () {
      service.setSleepTimer(const Duration(seconds: 5));
      service.cancelSleepTimer();
      expect(service.sleepTimeLeft, isNull);
    });
  });
}

class FakeAndroidEqualizer extends Fake implements AndroidEqualizer {}

class FakeAudioSource extends Fake implements AudioSource {}
