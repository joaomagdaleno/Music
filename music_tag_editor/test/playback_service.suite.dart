@Tags(['service'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:media_kit/media_kit.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/models/search_models.dart';
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
    registerFallbackValue(FakeMedia());
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

    // Wire up streams for mockPlayer as before
    final fakeStream = FakePlayerStream();
    when(() => mockPlayer.stream).thenReturn(fakeStream);
    when(() => mockPlayer.state).thenReturn(const PlayerState());

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
    when(() => mockPlayer.open(any(), play: any(named: 'play')))
        .thenAnswer((_) async {});
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

      verify(() => mockPlayer.open(any())).called(1);
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

class FakeMedia extends Fake implements Media {}
