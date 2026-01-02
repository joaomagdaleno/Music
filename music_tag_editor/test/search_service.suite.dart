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
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide SearchResult;
import 'test_helper.dart';

class MockDependencyManager extends Mock implements DependencyManager {}
class MockDatabaseService extends Mock implements DatabaseService {}
class MockHiFiDownloadService extends Mock implements HiFiDownloadService {}
class MockYoutubeExplode extends Mock implements YoutubeExplode {}
class MockSearchClient extends Mock implements SearchClient {}
class MockVideoSearchList extends Mock implements VideoSearchList {}
class MockVideo extends Mock implements Video {}

void main() {
  late SearchService service;
  late MockDependencyManager sMockDeps;
  late MockDatabaseService sMockDb;
  late MockHiFiDownloadService sMockHiFi;
  late MockYoutubeExplode mockYt;
  late MockSearchClient mockSearchClient;

  int mockExitCode = 0;
  String mockStdout = '';
  String mockStderr = '';

  setUp(() async {
    resetMocktailState();
    sMockDeps = MockDependencyManager();
    sMockDb = MockDatabaseService();
    sMockHiFi = MockHiFiDownloadService();
    mockYt = MockYoutubeExplode();
    mockSearchClient = MockSearchClient();

    mockExitCode = 0;
    mockStdout = '';
    mockStderr = '';

    DependencyManager.instance = sMockDeps;
    DatabaseService.instance = sMockDb;
    HiFiDownloadService.instance = sMockHiFi;

    SearchService.resetInstance();
    service = SearchService.instance;
    service.ytExplode = mockYt;

    when(() => mockYt.search).thenReturn(mockSearchClient);

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

    when(() => sMockDeps.ytDlpPath).thenReturn('yt-dlp');
    when(() => sMockDb.loadAgeBypass()).thenAnswer((_) async => false);
  });

  group('searchYouTube', () {
    test('returns parsed video results', () async {
      final mockVideo = MockVideo();
      when(() => mockVideo.id).thenReturn(VideoId('12345678901'));
      when(() => mockVideo.title).thenReturn('Test Title');
      when(() => mockVideo.author).thenReturn('Test Artist');
      when(() => mockVideo.url).thenReturn('http://url');
      when(() => mockVideo.thumbnails).thenReturn(ThumbnailSet('http://thumb'));
      when(() => mockVideo.duration).thenReturn(Duration(seconds: 180));
      
      final mockSearchList = MockVideoSearchList();
      when(() => mockSearchList.iterator).thenAnswer((_) => [mockVideo].iterator);
      
      when(() => mockSearchClient.search(any())).thenAnswer((_) async => mockSearchList);

      final results = await service.searchYouTube('query');

      expect(results.length, 1);
      expect(results[0].id, '12345678901');
      expect(results[0].title, 'Test Title');
      expect(results[0].platform, MediaPlatform.youtube);
    });

    test('returns empty list on error', () async {
      when(() => mockSearchClient.search(any())).thenThrow(Exception('YT Error'));
      final results = await service.searchYouTube('query');
      expect(results, isEmpty);
    });
  });

  group('searchYouTubeMusic', () {
    test('filters and parses results', () async {
      final mockVideo = MockVideo();
      when(() => mockVideo.id).thenReturn(VideoId('12345678901'));
      when(() => mockVideo.title).thenReturn('M Song');
      when(() => mockVideo.author).thenReturn('M Artist');
      when(() => mockVideo.url).thenReturn('http://murl');
      when(() => mockVideo.thumbnails).thenReturn(ThumbnailSet('http://mthumb'));
      when(() => mockVideo.duration).thenReturn(Duration(seconds: 200));

      final mockSearchList = MockVideoSearchList();
      when(() => mockSearchList.iterator).thenAnswer((_) => [mockVideo].iterator);

      when(() => mockSearchClient.search(any())).thenAnswer((_) async => mockSearchList);

      final results = await service.searchYouTubeMusic('query');

      expect(results.length, 1);
      expect(results[0].title, 'M Song');
      expect(results[0].platform, MediaPlatform.youtubeMusic);
      
      verify(() => mockSearchClient.search('query audio')).called(1);
    });
  });

  group('searchHiFi', () {
    test('delegates to HiFiDownloadService', () async {
      when(() => sMockHiFi.search(any())).thenAnswer((_) async => [
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
      mockStdout = '';
      when(() => sMockHiFi.search(any())).thenAnswer((_) async => []);

      final mockSearchList = MockVideoSearchList();
      when(() => mockSearchList.iterator).thenAnswer((_) => <Video>[].iterator);
      when(() => mockSearchClient.search(any())).thenAnswer((_) async => mockSearchList);

      final statuses = <MediaPlatform, List<SearchStatus>>{};
      await service.searchAll('query', onStatusUpdate: (p, s) {
        statuses.putIfAbsent(p, () => []).add(s);
      });

      expect(statuses.containsKey(MediaPlatform.youtube), true);
      expect(statuses[MediaPlatform.youtube], contains(SearchStatus.searching));
      expect(statuses[MediaPlatform.youtube], contains(SearchStatus.noResults));
    });
  });

  group('getFormats', () {
    test('returns default formats for Spotify', () async {
      final formats = await service.getFormats(
          'https://spotify.com/track/123', MediaPlatform.spotify);
      expect(formats.length, 3);
      expect(formats[0].extension, 'mp3');
    });

    test('parses yt-dlp json formats correctly', () async {
      final jsonOutput = jsonEncode({
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
            'resolution': '720p',
            'abr': null
          },
        ]
      });
      mockExitCode = 0;
      mockStdout = jsonOutput;

      final formats = await service.getFormats(
          'https://youtube.com/watch?v=123', MediaPlatform.youtube);

      expect(formats.any((f) => f.formatId == '140'), isTrue);
      expect(formats.any((f) => f.quality == '720p'), isTrue);
      expect(formats.any((f) => f.formatId == 'bestaudio/best'), isTrue);
    });
     test('returns default formats on process failure', () async {
      mockExitCode = 1;
      final formats = await service.getFormats(
          'https://youtube.com/watch?v=123', MediaPlatform.youtube);
      expect(formats.length, 2);
      expect(formats[0].formatId, 'bestaudio/best');
    });
  });

  group('importPlaylist', () {
    test('importYouTubePlaylist parses results correctly', () async {
      final jsonOutput = '${jsonEncode(
              {'id': 'v1', 'title': 'T1', 'uploader': 'A1', 'duration': 100})}\n${jsonEncode(
              {'id': 'v2', 'title': 'T2', 'uploader': 'A2', 'duration': 200})}';
      mockExitCode = 0;
      mockStdout = jsonOutput;

      final results =
          await service.importPlaylist('https://youtube.com/playlist?list=123');
      expect(results.length, 2);
      expect(results[0].title, 'T1');
      expect(results[1].artist, 'A2');
    });
  });

  group('findSpotifyMatch', () {
    test('returns match if available', () async {
      final ytResult = SearchResult(
          id: 'y1',
          title: 'Song',
          artist: 'Artist',
          url: '',
          platform: MediaPlatform.youtube);

      // Mock searchSpotify (via mockSearchClient) to return a match
      final mockVideo = MockVideo();
      when(() => mockVideo.id).thenReturn(VideoId('12345678901'));
      when(() => mockVideo.title).thenReturn('Song');
      when(() => mockVideo.author).thenReturn('Artist');
      when(() => mockVideo.url).thenReturn('http://surl');
      when(() => mockVideo.thumbnails).thenReturn(ThumbnailSet('http://sthumb'));
      when(() => mockVideo.duration).thenReturn(Duration(seconds: 180));

      final mockSearchList = MockVideoSearchList();
      when(() => mockSearchList.iterator).thenAnswer((_) => [mockVideo].iterator);
      when(() => mockSearchClient.search(any())).thenAnswer((_) async => mockSearchList);

      final match = await service.findSpotifyMatch(ytResult);
      expect(match, isNotNull);
      expect(match!.title, 'Song');
    });
  });
}
