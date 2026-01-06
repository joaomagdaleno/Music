@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_hub/features/discovery/services/search_service.dart';
import 'package:music_hub/core/services/dependency_manager.dart';
import 'package:music_hub/core/services/database_service.dart';
import 'package:music_hub/features/library/models/search_models.dart';
import 'package:music_hub/features/discovery/services/search/search_provider.dart';

class MockDependencyManager extends Mock implements DependencyManager {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockSearchProvider extends Mock implements SearchProvider {}

void main() {
  late SearchService service;
  late MockDependencyManager sMockDeps;
  late MockDatabaseService sMockDb;
  late MockSearchProvider mockYouTubeProvider;

  setUp(() async {
    resetMocktailState();
    sMockDeps = MockDependencyManager();
    sMockDb = MockDatabaseService();
    mockYouTubeProvider = MockSearchProvider();

    DependencyManager.instance = sMockDeps;
    DatabaseService.instance = sMockDb;

    SearchService.resetInstance();
    service = SearchService.instance;

    // mock provider setup
    when(() => mockYouTubeProvider.platform).thenReturn(MediaPlatform.youtube);
    service.setProviders([mockYouTubeProvider]);

    when(() => sMockDb.loadAgeBypass()).thenAnswer((_) async => false);
    when(() => sMockDb.getDownloadedUrls()).thenAnswer((_) async => {});
    when(() => sMockDb.getAllTracks()).thenAnswer((_) async => []);
  });

  group('searchAll', () {
    test('calls provider and updates status', () async {
      when(() => mockYouTubeProvider.search(any())).thenAnswer((_) async => []);

      final statuses = <MediaPlatform, List<SearchStatus>>{};
      await service.searchAll('query', onStatusUpdate: (p, s) {
        statuses.putIfAbsent(p, () => []).add(s);
      });

      verify(() => mockYouTubeProvider.search('query')).called(1);
      expect(statuses.containsKey(MediaPlatform.youtube), true);
      expect(statuses[MediaPlatform.youtube], contains(SearchStatus.searching));
      // returns empty list
      expect(statuses[MediaPlatform.youtube], contains(SearchStatus.noResults));
    });

    test('returns results from provider', () async {
      final result = SearchResult(
        id: '1',
        title: 'Test',
        artist: 'Artist',
        platform: MediaPlatform.youtube,
        url: 'http://test',
      );
      when(() => mockYouTubeProvider.search(any()))
          .thenAnswer((_) async => [result]);

      final results = await service.searchAll('query');

      expect(results.length, 1);
      expect(results.first.title, 'Test');
    });
  });

  group('getFormats', () {
    test('delegates to correct provider', () async {
      when(() => mockYouTubeProvider.supports(any())).thenReturn(true);
      when(() => mockYouTubeProvider.getFormats(any()))
          .thenAnswer((_) async => []);

      await service.getFormats('url', MediaPlatform.youtube);

      verify(() => mockYouTubeProvider.getFormats('url')).called(1);
    });
  });

  group('getStreamUrl', () {
    test('delegates to correct provider', () async {
      when(() => mockYouTubeProvider.supports(any())).thenReturn(true);
      when(() => mockYouTubeProvider.getStreamUrl(any()))
          .thenAnswer((_) async => 'http://stream');

      final url = await service.getStreamUrl('url');

      expect(url, 'http://stream');
    });
  });
}
