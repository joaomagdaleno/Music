import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/services/local_duo_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/services/equalizer_service.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/lyrics_service.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockBaseAudioHandler extends Mock implements BaseAudioHandler {
  @override
  final playbackState = BehaviorSubject<PlaybackState>();
  @override
  final mediaItem = BehaviorSubject<MediaItem?>();
}

class MockSearchService extends Mock implements SearchService {}

class MockLocalDuoService extends Mock implements LocalDuoService {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockThemeService extends Mock implements ThemeService {}

class MockEqualizerService extends Mock implements EqualizerService {}

class MockLyricsService extends Mock implements LyricsService {}

class MockMediaItem extends Mock implements MediaItem {}

class FakeAudioSource extends Fake implements AudioSource {}

void main() {
  late PlaybackService service;
  late MockAudioPlayer mockPlayer;
  late MockBaseAudioHandler mockHandler;
  late MockSearchService mockSearch;
  late MockLocalDuoService mockDuo;
  late MockDatabaseService mockDb;
  late MockThemeService mockTheme;
  late MockEqualizerService mockEqualizer;
  late MockLyricsService mockLyrics;

  final testTrack = SearchResult(
    id: '1',
    title: 'Test Song',
    artist: 'Test Artist',
    url: 'http://test',
    platform: MediaPlatform.youtube,
    genre: 'Pop',
    thumbnail: 'http://thumb',
    duration: 120,
  );

  setUpAll(() {
    registerFallbackValue(testTrack);
    registerFallbackValue(Duration.zero);
    registerFallbackValue(MediaItem(id: '1', title: 'T', artist: 'A'));
    registerFallbackValue(PlaybackState(
        processingState: AudioProcessingState.idle, playing: false));
    registerFallbackValue(FakeAudioSource());
  });

  setUp(() {
    mockPlayer = MockAudioPlayer();
    mockHandler = MockBaseAudioHandler();
    mockSearch = MockSearchService();
    mockDuo = MockLocalDuoService();
    mockDb = MockDatabaseService();
    mockTheme = MockThemeService();
    mockEqualizer = MockEqualizerService();
    mockLyrics = MockLyricsService();

    // Mock singletons
    LocalDuoService.instance = mockDuo;
    DatabaseService.instance = mockDb;
    ThemeService.instance = mockTheme;
    EqualizerService.instance = mockEqualizer;
    LyricsService.instance = mockLyrics;

    service =
        PlaybackService.forTesting(player: mockPlayer, handler: mockHandler);
    service.searchService = mockSearch;

    // Default stubs
    when(() => mockPlayer.play()).thenAnswer((_) => Future.value());
    when(() => mockPlayer.pause()).thenAnswer((_) => Future.value());
    when(() => mockPlayer.stop()).thenAnswer((_) => Future.value());
    when(() => mockPlayer.seek(any())).thenAnswer((_) => Future.value());
    when(() => mockPlayer.setAudioSource(any()))
        .thenAnswer((_) async => Duration.zero);
    when(() => mockPlayer.processingStateStream)
        .thenAnswer((_) => Stream.value(ProcessingState.idle));
    when(() => mockPlayer.playingStream).thenAnswer((_) => Stream.value(false));
    when(() => mockPlayer.positionStream)
        .thenAnswer((_) => Stream.value(Duration.zero));
    when(() => mockPlayer.currentIndexStream)
        .thenAnswer((_) => Stream.value(0));
    when(() => mockPlayer.position).thenReturn(Duration.zero);
    when(() => mockPlayer.speed).thenReturn(1.0);
    when(() => mockPlayer.bufferedPosition).thenReturn(Duration.zero);
    when(() => mockPlayer.processingState).thenReturn(ProcessingState.idle);
    when(() => mockPlayer.playing).thenReturn(false);
    when(() => mockPlayer.currentIndex).thenReturn(0);

    when(() => mockSearch.getStreamUrl(any()))
        .thenAnswer((_) async => 'http://stream');
    when(() => mockDuo.sendMessage(any())).thenReturn(null);
    when(() => mockDuo.sendFile(any())).thenAnswer((_) => Future.value());
    when(() => mockDb.trackPlay(any())).thenAnswer((_) => Future.value());
    when(() => mockDb.loadCrossfadeDuration()).thenAnswer((_) async => 3);
    when(() => mockEqualizer.applyPresetForGenre(any()))
        .thenAnswer((_) => Future.value());
    when(() => mockTheme.updateThemeFromImage(any()))
        .thenAnswer((_) => Future.value());
    when(() => mockLyrics.fetchLyrics(any(), any()))
        .thenAnswer((_) => Future.value([]));
  });

  group('playSearchResult', () {
    test('updates current track and plays', () async {
      await service.playSearchResult(testTrack);

      expect(service.currentTrack, testTrack);
      expect(service.queue, contains(testTrack));
      verify(() => mockPlayer.setAudioSource(any())).called(1);
      verify(() => mockPlayer.play()).called(1);
      verify(() => mockDuo.sendMessage(any())).called(1);
    });

    test('fetches lyrics and applies theme', () async {
      await service.playSearchResult(testTrack);

      verify(() => mockLyrics.fetchLyrics(testTrack.title, testTrack.artist))
          .called(1);
      verify(() => mockTheme.updateThemeFromImage(testTrack.thumbnail))
          .called(1);
      verify(() => mockEqualizer.applyPresetForGenre(testTrack.genre))
          .called(1);
    });
  });

  group('Queue Management', () {
    test('addToQueue adds to list and playlist', () async {
      // Setup initial playlist to avoid null check in service
      await service.playSearchResult(testTrack);

      final secondTrack = SearchResult(
          id: '2',
          title: 'T2',
          artist: 'A2',
          url: 'u2',
          platform: MediaPlatform.youtube);
      await service.addToQueue(secondTrack);

      expect(service.queue.length, 2);
      expect(service.queue[1], secondTrack);
      verify(() => mockDuo.sendMessage(any()))
          .called(2); // once for play, once for add
    });

    test('clearQueue empties the list', () {
      service.clearQueue();
      expect(service.queue, isEmpty);
    });
  });

  group('Sleep Timer', () {
    test('setSleepTimer initiates countdown', () async {
      final timerDuration = Duration(seconds: 2);
      service.setSleepTimer(timerDuration);

      expect(service.sleepTimeLeft, timerDuration);

      // Wait for timer to tick
      await Future.delayed(Duration(seconds: 1, milliseconds: 100));
      // Wait for timer to tick: 1 -> 0
      await Future.delayed(Duration(seconds: 1, milliseconds: 200));
      expect(service.sleepTimeLeft!.inSeconds, 0);

      // Wait for the next tick to trigger cancel
      await Future.delayed(Duration(seconds: 1, milliseconds: 200));
      expect(service.sleepTimeLeft, null); // Cancelled after reaching 0
      verify(() => mockPlayer.stop()).called(1);
    });

    test('cancelSleepTimer clears timer', () {
      service.setSleepTimer(Duration(minutes: 5));
      service.cancelSleepTimer();
      expect(service.sleepTimeLeft, null);
    });
  });

  group('Controls', () {
    test('pause/resume delegates to player', () async {
      await service.pause();
      verify(() => mockPlayer.pause()).called(1);

      await service.resume();
      verify(() => mockPlayer.play()).called(1);
    });

    test('seek delegates to player and sends message', () async {
      final pos = Duration(seconds: 30);
      await service.seek(pos);
      verify(() => mockPlayer.seek(pos)).called(1);
      verify(() => mockDuo.sendMessage(any())).called(1);
    });
  });
}
