@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/listening_stats_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late ListeningStatsService service;
  late MockDatabaseService mockDb;

  setUp(() {
    mockDb = MockDatabaseService();
    service = ListeningStatsService.test(db: mockDb);
  });

  group('ListeningStatsService', () {
    test('getStats calculates basic totals correctly', () async {
      final mockTracks = [
        {
          'title': 'Track 1',
          'play_count': 10,
          'duration': 180,
          'artist': 'Artist A',
          'genre': 'Rock'
        },
        {
          'title': 'Track 2',
          'play_count': 5,
          'duration': 200,
          'artist': 'Artist B',
          'genre': 'Pop'
        },
        {
          'title': 'Track 3',
          'play_count': 0,
          'duration': 150,
          'artist': 'Artist A',
          'genre': 'Rock'
        },
      ];

      when(() => mockDb.getTracks()).thenAnswer((_) async => mockTracks);

      final stats = await service.getStats();

      expect(stats.totalTracks, 3);
      expect(stats.totalPlays, 15);
      expect(
          stats.estimatedListeningTime, Duration(seconds: 10 * 180 + 5 * 200));
    });

    test('getStats identifies top items correctly', () async {
      final mockTracks = [
        {
          'title': 'Top 1',
          'play_count': 100,
          'artist': 'Queen',
          'genre': 'Rock'
        },
        {
          'title': 'Top 2',
          'play_count': 50,
          'artist': 'Queen',
          'genre': 'Rock'
        },
        {'title': 'Top 3', 'play_count': 10, 'artist': 'Abba', 'genre': 'Pop'},
        {'title': 'Top 4', 'play_count': 5, 'artist': 'Abba', 'genre': 'Pop'},
        {
          'title': 'Top 5',
          'play_count': 2,
          'artist': 'Unknown',
          'genre': 'Jazz'
        },
      ];

      when(() => mockDb.getTracks()).thenAnswer((_) async => mockTracks);

      final stats = await service.getStats();

      // Top Tracks
      expect(stats.topTracks.first['title'], 'Top 1');
      expect(stats.topTracks.length, 5);

      // Top Artists
      // Queen: 150 plays, Abba: 15 plays, Unknown: 2
      expect(stats.topArtists.first.key, 'Queen');
      expect(stats.topArtists.first.value, 150);
      expect(stats.topArtists[1].key, 'Abba');

      // Top Genres
      // Rock: 150, Pop: 15, Jazz: 2
      expect(stats.topGenres.first.key, 'Rock');
      expect(stats.topGenres.first.value, 150);
    });

    test('getStats handles empty database', () async {
      when(() => mockDb.getTracks()).thenAnswer((_) async => []);

      final stats = await service.getStats();

      expect(stats.totalTracks, 0);
      expect(stats.totalPlays, 0);
      expect(stats.topTracks, isEmpty);
      expect(stats.topArtists, isEmpty);
      expect(stats.topGenres, isEmpty);
    });
  });
}
