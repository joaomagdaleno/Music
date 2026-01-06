@Tags(['service'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_hub/features/player/services/playback_service.dart';
import 'package:music_hub/features/library/models/search_models.dart';
import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';
import 'test_helper.dart';

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

// Mocks are now sourced from test_helper.dart

void main() {
  late MockPlayer mockPlayer;
  late MockBaseAudioHandler mockAudioHandler;
  late PlaybackService service;

  setUpAll(() {
  });

  setUp(() async {
    await setupMusicTest();

    // Re-initialize PlaybackService with mocks for this suite
    PlaybackService
        .resetInstance(); // Ensure we use a clean instance if possible, or force mocks
    // PlaybackService.instance is a singleton. In test_helper we assign PlaybackService.instance = mockPlayback.
    // But here we want to TEST the REAL PlaybackService using mock Player.

    // So we use the forTesting constructor.
    mockPlayer = MockPlayer();
    mockPlayer = MockPlayer();
    mockAudioHandler = MockBaseAudioHandler();

    // Wire up MockPlayer properties
    when(() => mockPlayer.playerStateStream).thenAnswer((_) => Stream.value(PlayerState(false, ProcessingState.idle)));
    when(() => mockPlayer.positionStream).thenAnswer((_) => Stream.value(Duration.zero));
    when(() => mockPlayer.bufferedPositionStream).thenAnswer((_) => Stream.value(Duration.zero));
    when(() => mockPlayer.playingStream).thenAnswer((_) => Stream.value(false));
    when(() => mockPlayer.durationStream).thenAnswer((_) => Stream.value(null));
    when(() => mockPlayer.sequenceStateStream).thenAnswer((_) => const Stream.empty());

    service = PlaybackService.forTesting(
      player: mockPlayer,
      handler: mockAudioHandler,
    );
    PlaybackService.instance = service; // Assign to singleton

    // Stubs
    when(() => mockSearch.getStreamUrl(any(), platform: any(named: 'platform')))
        .thenAnswer((_) async => 'http://stream.url');
    when(() => mockLyrics.fetchLyrics(any(), any()))
        .thenAnswer((_) async => []);
    when(() => mockPlayer.setAudioSource(any(), initialPosition: any(named: 'initialPosition'), preload: any(named: 'preload')))
        .thenAnswer((_) async => null);
    when(() => mockPlayer.play()).thenAnswer((_) async {});
    when(() => mockPlayer.pause()).thenAnswer((_) async {});
    when(() => mockPlayer.stop()).thenAnswer((_) async {});
    when(() => mockPlayer.seek(any())).thenAnswer((_) async {});
  });

  group('PlaybackService Tests', () {
    test('playSearchResult opens media and updates queue', () async {
      final track = SearchResult(
          id: '1',
          title: 'Title',
          artist: 'Artist',
          url: 'url',
          platform: MediaPlatform.youtube,
          thumbnail: 'http://thumb');

      await service.playSearchResult(track);

      verify(() => mockPlayer.setAudioSource(any())).called(1);
      expect(service.currentTrack, track);
      expect(service.queue.contains(track), true);
    });

    test('pause pauses player', () async {
      await service.pause();
      verify(() => mockPlayer.pause()).called(1);
    });

    test('resume plays player', () async {
      await service.resume();
      verify(() => mockPlayer.play()).called(1);
    });

    test('stop stops player', () async {
      await service.stop();
      verify(() => mockPlayer.stop()).called(1);
      expect(service.currentTrack, null);
    });
  });
}

