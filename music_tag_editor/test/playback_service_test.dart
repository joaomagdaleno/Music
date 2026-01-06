import 'package:rxdart/rxdart.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
// import 'package:just_audio/just_audio.dart'; // Removed
import 'package:audio_service/audio_service.dart';
import 'package:music_hub/features/player/services/playback_service.dart';
import 'package:music_hub/models/search_models.dart';
import 'test_helper.dart';

// Mocks are now sourced from test_helper.dart
class MockBaseAudioHandler extends Mock implements BaseAudioHandler {
  @override
  final playbackState = BehaviorSubject<PlaybackState>();
  @override
  final mediaItem = BehaviorSubject<MediaItem?>();

  void dispose() {
    playbackState.close();
    mediaItem.close();
  }
}

class MockMediaItem extends Mock implements MediaItem {}

void main() {
  late PlaybackService service;
  late MockBaseAudioHandler mockHandler;

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
    registerFallbackValue(const MediaItem(id: '1', title: 'T', artist: 'A'));
    registerFallbackValue(PlaybackState(
        processingState: AudioProcessingState.idle, playing: false));
  });

  setUp(() async {
    await setupMusicTest();
    mockHandler = MockBaseAudioHandler();

    // PlaybackService needs specific handler for testing
    service = PlaybackService.forTesting(
        player: mockPlayer, handler: mockHandler); // Passed to constructor
    // service.searchService = mockSearch; // Injected via singleton

    // Additional stubs for this test specifically
    when(() => mockHandler.play()).thenAnswer((_) async {});
    when(() => mockHandler.pause()).thenAnswer((_) async {});
    when(() => mockHandler.stop()).thenAnswer((_) async {});
    when(() => mockHandler.seek(any())).thenAnswer((_) async {});
    when(() => mockHandler.addQueueItem(any())).thenAnswer((_) async {});
    when(() => mockHandler.removeQueueItem(any())).thenAnswer((_) async {});

    // Stub mockPlayer methods used in PlaybackService
    // Note: Most checks are redundant as setupMusicTest provides default stubs.
    // However, verify calls need these to be valid.

    when(() => mockPlayer.open(any(), play: any(named: 'play')))
        .thenAnswer((_) async {});

    when(() => mockSearch.getStreamUrl(
          any(),
          platform: any(named: 'platform'),
        )).thenAnswer((_) async => 'http://stream');
    when(() => mockLyrics.fetchLyrics(any(), any()))
        .thenAnswer((_) => Future.value([]));
  });

  group('playSearchResult', () {
    test('updates current track and plays', () async {
      await service.playSearchResult(testTrack);

      expect(service.currentTrack, testTrack);
      expect(service.queue, contains(testTrack));
      // Verify usage of media_kit open with play: true
      verify(() => mockPlayer.open(any(), play: true)).called(1);
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
      const timerDuration = Duration(seconds: 2);
      service.setSleepTimer(timerDuration);

      expect(service.sleepTimeLeft, timerDuration);

      // Wait for timer to tick
      await Future.delayed(const Duration(seconds: 1, milliseconds: 100));
      // Wait for timer to tick: 1 -> 0
      await Future.delayed(const Duration(seconds: 1, milliseconds: 200));
      expect(service.sleepTimeLeft!.inSeconds, 0);

      // Wait for the next tick to trigger cancel
      await Future.delayed(const Duration(seconds: 1, milliseconds: 200));
      expect(service.sleepTimeLeft, null); // Cancelled after reaching 0
      verify(() => mockPlayer.stop()).called(1);
    });

    test('cancelSleepTimer clears timer', () {
      service.setSleepTimer(const Duration(minutes: 5));
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
      const pos = Duration(seconds: 30);
      await service.seek(pos);
      verify(() => mockPlayer.seek(pos)).called(1);
      verify(() => mockDuo.sendMessage(any())).called(1);
    });
  });
}
// IGNORE_TESTS_TEMPORARILY
