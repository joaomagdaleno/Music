@Tags(['unit'])
library;

import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';

void main() {
  late DownloadService service;

  setUp(() {
    DependencyManager.instance = DependencyManager.forTesting();
    service = DownloadService.instance;
  });

  group('DownloadService - Platform Detection', () {
    test('detects YouTube correctly', () {
      expect(service.detectPlatform('https://www.youtube.com/watch?v=abc'),
          equals(MediaPlatform.youtube));
      expect(service.detectPlatform('https://youtu.be/abc'),
          equals(MediaPlatform.youtube));
    });

    test('detects YouTube Music correctly', () {
      expect(service.detectPlatform('https://music.youtube.com/watch?v=abc'),
          equals(MediaPlatform.youtubeMusic));
    });

    test('detects Spotify correctly', () {
      expect(service.detectPlatform('https://open.spotify.com/track/abc'),
          equals(MediaPlatform.spotify));
    });

    test('returns unknown for invalid URLs', () {
      expect(service.detectPlatform('https://google.com'),
          equals(MediaPlatform.unknown));
      expect(
          service.detectPlatform('not-a-url'), equals(MediaPlatform.unknown));
    });
  });

  group('DownloadService - Media Info', () {
    test('getMediaInfo returns YouTube info correctly', () async {
      final jsonOutput = jsonEncode({
        'title': 'Test Song',
        'uploader': 'Test Artist',
        'album': 'Test Album',
        'thumbnail': 'http://thumb.jpg',
        'duration': 180,
        'formats': [
          {
            'format_id': '140',
            'ext': 'm4a',
            'acodec': 'mp4a',
            'vcodec': 'none',
            'abr': 128
          },
          {
            'format_id': '22',
            'ext': 'mp4',
            'acodec': 'mp4a',
            'vcodec': 'avc1',
            'resolution': '720p'
          },
        ],
      });

      final result = ProcessResult(0, 0, jsonOutput, '');

      service.processRunner = (
        executable,
        arguments, {
        environment,
        includeParentEnvironment = true,
        runInShell = false,
        stdoutEncoding,
        stderrEncoding,
      }) async {
        return result;
      };

      final info =
          await service.getMediaInfo('https://youtube.com/watch?v=abc');

      expect(info.title, equals('Test Song'));
      expect(info.artist, equals('Test Artist'));
      expect(info.platform, equals(MediaPlatform.youtube));
      expect(info.formats.any((f) => f.formatId == '140'), isTrue);
    });

    test('getMediaInfo returns Spotify info correctly', () async {
      final info =
          await service.getMediaInfo('https://open.spotify.com/track/abc');
      expect(info.platform, equals(MediaPlatform.spotify));
      expect(info.title, equals('Spotify Track'));
    });
  });
}
