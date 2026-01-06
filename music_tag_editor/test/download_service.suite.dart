@Tags(['unit'])
library;

import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_hub/features/discovery/services/download_service.dart';
import 'package:music_hub/models/search_models.dart';
import 'package:music_hub/core/services/dependency_manager.dart';
import 'package:music_hub/features/discovery/services/download/youtube_download_provider.dart';
import 'test_helper.dart';

void main() {
  setUp(() async {
    await setupMusicTest(mockDownloadInstance: false);
    DependencyManager.instance = DependencyManager.forTesting();
  });

  group('DownloadService - Platform Detection', () {
    test('detects YouTube correctly', () {
      expect(
          DownloadService.detectPlatform('https://www.youtube.com/watch?v=abc'),
          equals(MediaPlatform.youtube));
      expect(DownloadService.detectPlatform('https://youtu.be/abc'),
          equals(MediaPlatform.youtube));
    });

    test('detects YouTube Music correctly', () {
      expect(
          DownloadService.detectPlatform(
              'https://music.youtube.com/watch?v=abc'),
          equals(MediaPlatform.youtubeMusic));
    });

    test('returns unknown for invalid URLs', () {
      expect(DownloadService.detectPlatform('https://google.com'),
          equals(MediaPlatform.unknown));
      expect(DownloadService.detectPlatform('not-a-url'),
          equals(MediaPlatform.unknown));
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

      final provider = YouTubeDownloadProvider(
        processRunner: (
          executable,
          arguments, {
          workingDirectory,
          environment,
          includeParentEnvironment = true,
          runInShell = false,
          stdoutEncoding,
          stderrEncoding,
        }) async =>
            result,
      );

      final info = await provider.getInfo('https://youtube.com/watch?v=abc');

      expect(info.title, equals('Test Song'));
      expect(info.artist, equals('Test Artist'));
      expect(info.platform, equals(MediaPlatform.youtube));
      expect(info.formats.any((f) => f.formatId == '140'), isTrue);
    });
  });
}
