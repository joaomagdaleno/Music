@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/services/metadata_cleanup_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/metadata_aggregator_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

class MockMetadataAggregatorService extends Mock
    implements MetadataAggregatorService {}

void main() {
  late MetadataCleanupService service;
  late MockDatabaseService mockDb;
  late MockMetadataAggregatorService mockAggregator;

  setUp(() {
    mockDb = MockDatabaseService();
    mockAggregator = MockMetadataAggregatorService();

    DatabaseService.instance = mockDb;
    MetadataAggregatorService.instance = mockAggregator;
    service = MetadataCleanupService.instance;

    // Default stubs
    when(() => mockDb.saveTrack(any())).thenAnswer((_) async {});
  });

  group('MetadataCleanupService', () {
    test('cleanupLibrary cleans dirty titles and artists', () async {
      final dirtyTracks = [
        {
          'id': '1',
          'title': 'Song Title [Official Video]',
          'artist': 'Artist (Official Audio)',
          'genre': 'Pop',
          'album': 'Album',
          'path': '/path/1.mp3'
        }
      ];

      when(() => mockDb.getTracks()).thenAnswer((_) async => dirtyTracks);

      final count = await service.cleanupLibrary();

      expect(count, equals(1));
      verify(() =>
          mockDb.saveTrack(any(that: predicate((Map<String, dynamic> track) {
            return track['title'] == 'Song Title' &&
                track['artist'] == 'Artist';
          })))).called(1);
    });

    test('cleanupLibrary fetches missing metadata', () async {
      final missingMetaTracks = [
        {
          'id': '2',
          'title': 'Clean Title',
          'artist': 'Clean Artist',
          'genre': '', // Empty
          'album': null, // Null
          'path': '/path/2.mp3'
        }
      ];

      when(() => mockDb.getTracks()).thenAnswer((_) async => missingMetaTracks);

      // Mock aggregator response
      when(() =>
              mockAggregator.aggregateMetadata('Clean Title', 'Clean Artist'))
          .thenAnswer((_) async => AggregatedMetadata(
                title: 'Clean Title',
                artist: 'Clean Artist',
                genre: 'Rock',
                album: 'Best Hits',
                year: 2023,
              ));

      final count = await service.cleanupLibrary();

      expect(count, equals(1));
      verify(() =>
          mockDb.saveTrack(any(that: predicate((Map<String, dynamic> track) {
            return track['genre'] == 'Rock' && track['album'] == 'Best Hits';
          })))).called(1);
    });

    test('cleanupLibrary handles aggregator errors gracefully', () async {
      final missingMetaTracks = [
        {
          'id': '3',
          'title': 'Unknown Song',
          'artist': 'Unknown Artist',
        }
      ];

      when(() => mockDb.getTracks()).thenAnswer((_) async => missingMetaTracks);
      when(() => mockAggregator.aggregateMetadata(any(), any()))
          .thenThrow(Exception('API Error'));

      final count = await service.cleanupLibrary();

      expect(count, equals(0));
      verifyNever(() => mockDb.saveTrack(any()));
    });
  });
}
