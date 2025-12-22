import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_player/search_service.dart';
import 'package:music_player/download_service.dart';
import 'package:music_player/dependency_manager.dart';

class MockDependencyManager extends Mock implements DependencyManager {}

// We use real ProcessResult because it's a final class and cannot be implemented
ProcessResult createMockProcessResult({
  int exitCode = 0,
  String stdout = '',
  String stderr = '',
}) {
  return ProcessResult(0, exitCode, stdout, stderr);
}

void main() {
  group('SearchService Tests', () {
    late SearchService searchService;
    late MockDependencyManager mockDeps;

    setUp(() {
      mockDeps = MockDependencyManager();
      DependencyManager.instance = mockDeps;
      searchService = SearchService();

      when(() => mockDeps.ytDlpPath).thenReturn('yt-dlp');
      when(() => mockDeps.spotdlPath).thenReturn('spotdl');
    });

    test('searchYouTube returns results on success', () async {
      final mockResult = createMockProcessResult(
        stdout: jsonEncode({
          'id': 'test_id',
          'title': 'Test Song',
          'channel': 'Test Artist',
          'thumbnail': 'https://example.com/thumb.jpg',
          'duration': 180,
        }),
      );

      searchService.processRunner = (executable, arguments,
          {environment,
          includeParentEnvironment = true,
          runInShell = false,
          stdoutEncoding,
          stderrEncoding}) async {
        return mockResult;
      };

      final results = await searchService.searchYouTube('test query');

      expect(results.length, 1);
      expect(results.first.title, 'Test Song');
      expect(results.first.artist, 'Test Artist');
      expect(results.first.platform, MediaPlatform.youtube);
    });

    test('searchYouTube returns empty list on failure', () async {
      final mockResult = createMockProcessResult(exitCode: 1);

      searchService.processRunner = (executable, arguments,
          {environment,
          includeParentEnvironment = true,
          runInShell = false,
          stdoutEncoding,
          stderrEncoding}) async {
        return mockResult;
      };

      final results = await searchService.searchYouTube('test query');
      expect(results, isEmpty);
    });

    test('getStreamUrl returns url on success', () async {
      final mockResult =
          createMockProcessResult(stdout: 'https://stream.url\n');

      searchService.processRunner = (executable, arguments,
          {environment,
          includeParentEnvironment = true,
          runInShell = false,
          stdoutEncoding,
          stderrEncoding}) async {
        return mockResult;
      };

      final url =
          await searchService.getStreamUrl('https://youtube.com/watch?v=abc');
      expect(url, 'https://stream.url');
    });
  });
}
