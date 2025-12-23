import 'package:flutter_test/flutter_test.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/download_service.dart';

void main() {
  group('PlaybackService', () {
    test('instance is accessible', () {
      expect(PlaybackService.instance, isNotNull);
    });

    test('queue is a list', () {
      expect(PlaybackService.instance.queue, isA<List<SearchResult>>());
    });

    test('currentTrack is nullable SearchResult', () {
      final track = PlaybackService.instance.currentTrack;
      if (track != null) {
        expect(track, isA<SearchResult>());
      } else {
        expect(track, isNull);
      }
    });

    test('sleepTimerStream is a stream', () {
      expect(
          PlaybackService.instance.sleepTimerStream, isA<Stream<Duration?>>());
    });

    test('lyricsStream is a stream', () {
      expect(PlaybackService.instance.lyricsStream, isA<Stream>());
    });

    test('addToQueue does not throw', () {
      final track = SearchResult(
        id: 'test',
        title: 'Test',
        artist: 'Test Artist',
        url: 'http://test',
        platform: MediaPlatform.youtube,
      );

      expect(() => PlaybackService.instance.addToQueue(track), returnsNormally);
    });
  });
}
