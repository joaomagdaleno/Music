import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/hifi_download_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class MockDependencyManager extends Mock implements DependencyManager {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockHiFiDownloadService extends Mock implements HiFiDownloadService {}

class MockYoutubeExplode extends Mock implements YoutubeExplode {}

class MockSearchClient extends Mock implements SearchClient {}

// In 3.x, search returns VideoSearchList which we need to mock or return a subtype
class MockVideoSearchList extends Mock implements VideoSearchList {}

// Mock Video to avoid constructor changes issues
class MockVideo extends Mock implements Video {}

void main() {
  late SearchService service;
  late MockDependencyManager mockDeps;
  late MockDatabaseService mockDb;
  late MockHiFiDownloadService mockHiFi;
  
  // Mock YoutubeExplode
  late MockYoutubeExplode mockYt;
  late MockSearchClient mockSearchClient;

  int mockExitCode = 0;
  String mockStdout = '';
  String mockStderr = '';

  setUp(() {
    resetMocktailState();
    mockDeps = MockDependencyManager();
    mockDb = MockDatabaseService();
    mockHiFi = MockHiFiDownloadService();
    
    // Setup YT mocks
    mockYt = MockYoutubeExplode();
    mockSearchClient = MockSearchClient();
    when(() => mockYt.search).thenReturn(mockSearchClient);

    mockExitCode = 0;
    mockStdout = '';
    mockStderr = '';

    DependencyManager.instance = mockDeps;
    DatabaseService.instance = mockDb;
    HiFiDownloadService.instance = mockHiFi;

    SearchService.resetInstance(); // FORCE RESET
    service = SearchService.instance;
    service.ytExplode = mockYt; // Inject mock

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
      
      // Verify " audio" was appended
      verify(() => mockSearchClient.search('query audio')).called(1);
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
}
