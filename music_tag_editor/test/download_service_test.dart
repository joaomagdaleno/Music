import 'package:flutter_test/flutter_test.dart';
import 'package:music_tag_editor/services/download_service.dart';

void main() {
  group('SearchResult', () {
    test('can be instantiated', () {
      final result = SearchResult(
        id: '1',
        title: 'Test Song',
        artist: 'Test Artist',
        url: 'http://test.com/song',
        platform: MediaPlatform.youtube,
      );

      expect(result.id, '1');
      expect(result.title, 'Test Song');
      expect(result.artist, 'Test Artist');
    });

    test('toJson returns map', () {
      final result = SearchResult(
        id: '1',
        title: 'Test Song',
        artist: 'Test Artist',
        url: 'http://test.com/song',
        platform: MediaPlatform.youtube,
      );

      final json = result.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], '1');
      expect(json['title'], 'Test Song');
    });

    test('duration is nullable int', () {
      final result = SearchResult(
        id: '1',
        title: 'Test Song',
        artist: 'Test Artist',
        url: 'http://test.com/song',
        platform: MediaPlatform.youtube,
        duration: 210, // seconds
      );

      expect(result.duration, 210);
    });

    test('thumbnail is nullable', () {
      final result = SearchResult(
        id: '1',
        title: 'Test Song',
        artist: 'Test Artist',
        url: 'http://test.com/song',
        platform: MediaPlatform.youtube,
        thumbnail: 'http://example.com/thumb.jpg',
      );

      expect(result.thumbnail, 'http://example.com/thumb.jpg');
    });
  });

  group('MediaPlatform', () {
    test('has expected values', () {
      expect(MediaPlatform.values, contains(MediaPlatform.youtube));
      expect(MediaPlatform.values, contains(MediaPlatform.spotify));
      expect(MediaPlatform.values, contains(MediaPlatform.unknown));
    });
  });

  group('DownloadService', () {
    test('instance is accessible', () {
      expect(DownloadService.instance, isNotNull);
    });
  });
}
