@Tags(['unit'])
library;

import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/hifi_download_service.dart';

class MockDependencyManager extends Mock implements DependencyManager {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockHiFiDownloadService extends Mock implements HiFiDownloadService {}

void main() {
  late SearchService service;
  late MockDependencyManager mockDeps;
  late MockDatabaseService mockDb;
  late MockHiFiDownloadService mockHiFi;

  int mockExitCode = 0;
  String mockStdout = '';
  String mockStderr = '';

  setUp(() {
    mockDeps = MockDependencyManager();
    mockDb = MockDatabaseService();
    mockHiFi = MockHiFiDownloadService();

    mockExitCode = 0;
    mockStdout = '';
    mockStderr = '';

    DependencyManager.instance = mockDeps;
    DatabaseService.instance = mockDb;
    HiFiDownloadService.instance = mockHiFi;

    service = SearchService.instance;

    // Inject mock runner
    service.processRunner = (
      executable,
      arguments, {
      environment,
      includeParentEnvironment = true,
      runInShell = false,
      stdoutEncoding,
      stderrEncoding,
    }) async {
      return ProcessResult(0, mockExitCode, mockStdout, mockStderr);
    };

    when(() => mockDeps.ytDlpPath).thenReturn('yt-dlp');
    when(() => mockDb.loadAgeBypass()).thenAnswer((_) async => false);
  });

  group('searchYouTube', () {
    test('parses yt-dlp json output correctly', () async {
      final jsonOutput = jsonEncode({
        'id': 'vid123',
        'title': 'Test Title',
        'channel': 'Test Artist',
        'thumbnail': 'http://thumb',
        'duration': 180,
      });

      mockExitCode = 0;
      mockStdout = jsonOutput;

      final results = await service.searchYouTube('query');

      expect(results.length, 1);
      expect(results[0].id, 'vid123');
      expect(results[0].title, 'Test Title');
      expect(results[0].artist, 'Test Artist');
      expect(results[0].platform, MediaPlatform.youtube);
    });

    test('returns empty list on process error', () async {
      mockExitCode = 1;
      final results = await service.searchYouTube('query');
      expect(results, isEmpty);
    });
  });

  group('searchYouTubeMusic', () {
    test('parses yt-music output with album info', () async {
      final jsonOutput = jsonEncode({
        'id': 'm123',
        'title': 'M Song',
        'artist': 'M Artist',
        'album': 'M Album',
        'thumbnail': 'http://mthumb',
        'duration': 200,
      });

      mockExitCode = 0;
      mockStdout = jsonOutput;

      final results = await service.searchYouTubeMusic('query');

      expect(results.length, 1);
      expect(results[0].title, 'M Song');
      expect(results[0].album, 'M Album');
      expect(results[0].platform, MediaPlatform.youtubeMusic);
    });
  });

  group('searchHiFi', () {
    test('delegates to HiFiDownloadService', () async {
      when(() => mockHiFi.search(any())).thenAnswer((_) async => [
            HiFiSearchResult(
              id: 'h1',
              title: 'H Title',
              artist: 'H Artist',
              source: HiFiSource.qobuz,
              sourceUrl: 'http://h',
              quality: 'FLAC',
            ),
          ]);

      final results = await service.searchHiFi('query');
      expect(results.length, 1);
      expect(results[0].platform, MediaPlatform.hifi);
    });
  });

  group('getStreamUrl', () {
    test('returns trimmed stdout on success', () async {
      mockExitCode = 0;
      mockStdout = '  http://direct-url  \n';

      final url = await service.getStreamUrl('http://origin');
      expect(url, 'http://direct-url');
    });

    test('returns null on failure', () async {
      mockExitCode = 1;
      final url = await service.getStreamUrl('http://origin');
      expect(url, isNull);
    });
  });

  group('searchAll', () {
    test('calls all platforms and updates status', () async {
      mockExitCode = 0;
      mockStdout = ''; // Empty results for simplicity
      when(() => mockHiFi.search(any())).thenAnswer((_) async => []);

      final statuses = <MediaPlatform, List<SearchStatus>>{};
      await service.searchAll('query', onStatusUpdate: (p, s) {
        statuses.putIfAbsent(p, () => []).add(s);
      });

      expect(statuses.containsKey(MediaPlatform.youtube), true);
      expect(statuses[MediaPlatform.youtube], contains(SearchStatus.searching));
      expect(statuses[MediaPlatform.youtube], contains(SearchStatus.noResults));
    });
  });
}
