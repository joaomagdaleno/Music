import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/metadata_aggregator_service.dart';
import 'package:music_tag_editor/musicbrainz_api.dart';
import 'package:music_tag_editor/lastfm_api.dart';
import 'package:music_tag_editor/discogs_api.dart';
import 'package:music_tag_editor/genius_api.dart';
import 'package:music_tag_editor/netease_api.dart';
import 'package:music_tag_editor/lyrics_service.dart';

class MockMusicBrainzApi extends Mock implements MusicBrainzApi {}

class MockLastFmApi extends Mock implements LastFmApi {}

class MockDiscogsApi extends Mock implements DiscogsApi {}

class MockGeniusApi extends Mock implements GeniusApi {}

class MockNeteaseApi extends Mock implements NeteaseApi {}

class MockLyricsService extends Mock implements LyricsService {}

void main() {
  late MetadataAggregatorService service;
  late MockMusicBrainzApi mockMusicBrainz;
  late MockLastFmApi mockLastFm;
  late MockDiscogsApi mockDiscogs;
  late MockGeniusApi mockGenius;
  late MockNeteaseApi mockNetease;
  late MockLyricsService mockLyrics;

  setUp(() {
    mockMusicBrainz = MockMusicBrainzApi();
    mockLastFm = MockLastFmApi();
    mockDiscogs = MockDiscogsApi();
    mockGenius = MockGeniusApi();
    mockNetease = MockNeteaseApi();
    mockLyrics = MockLyricsService();

    service = MetadataAggregatorService.instance;
    service.setDependencies(
      musicBrainz: mockMusicBrainz,
      lastFm: mockLastFm,
      discogs: mockDiscogs,
      genius: mockGenius,
      netease: mockNetease,
      lrcLib: mockLyrics,
    );
  });

  group('aggregateMetadata', () {
    test('aggregates results correctly with majority vote', () async {
      when(() => mockMusicBrainz.searchMetadata(any(), any()))
          .thenAnswer((_) async => [
                {
                  'title': 'Correct Title',
                  'artist': 'Correct Artist',
                  'album': 'Correct Album',
                  'genres': ['Pop'],
                }
              ]);
      when(() => mockLastFm.getTrackInfo(any(), any()))
          .thenAnswer((_) async => {
                'name': 'Correct Title',
                'artist': 'Correct Artist',
                'album': 'Correct Album',
              });
      when(() => mockDiscogs.searchRelease(any(), any()))
          .thenAnswer((_) async => {
                'title': 'Wrong Title', // Minority
                'year': 2023,
                'genre': 'Pop',
                'style': 'Dance',
                'cover': 'http://cover.jpg',
              });
      when(() => mockGenius.searchSong(any(), any()))
          .thenAnswer((_) async => null);

      final result = await service.aggregateMetadata('Title', 'Artist');

      expect(result.title, 'Correct Title'); // 2 vs 1
      expect(result.artist, 'Correct Artist');
      expect(result.album, 'Correct Album');
      expect(result.year, 2023); // From Discogs alone
      expect(result.thumbnail, 'http://cover.jpg');
      expect(result.allGenres, contains('Pop'));
      expect(result.confidence, greaterThan(0.5));
    });

    test('handles empty results', () async {
      when(() => mockMusicBrainz.searchMetadata(any(), any()))
          .thenAnswer((_) async => []);
      when(() => mockLastFm.getTrackInfo(any(), any()))
          .thenAnswer((_) async => null);
      when(() => mockDiscogs.searchRelease(any(), any()))
          .thenAnswer((_) async => null);
      when(() => mockGenius.searchSong(any(), any()))
          .thenAnswer((_) async => null);

      final result = await service.aggregateMetadata('Title', 'Artist');

      expect(result.title, null);
      expect(result.artist, null);
      expect(result.confidence, 0.0);
    });
  });

  group('fetchSyncedLyrics', () {
    test('returns lyrics from LrcLib if found and valid', () async {
      final lyrics = [LyricLine(time: Duration(seconds: 10), text: 'Line 1')];
      when(() => mockLyrics.fetchLyrics(any(), any()))
          .thenAnswer((_) async => lyrics);

      final result =
          await service.fetchSyncedLyrics('Title', 'Artist', durationMs: 10000);

      expect(result, lyrics);
      verify(() => mockLyrics.fetchLyrics(any(), any())).called(1);
      verifyNever(() => mockNetease.fetchSyncedLyrics(any(), any()));
    });

    test('falls back to Netease if LrcLib empty', () async {
      when(() => mockLyrics.fetchLyrics(any(), any()))
          .thenAnswer((_) async => []);
      final lyrics = [
        LyricLine(time: Duration(seconds: 10), text: 'Netease Line')
      ];
      when(() => mockNetease.fetchSyncedLyrics(any(), any()))
          .thenAnswer((_) async => lyrics);

      final result = await service.fetchSyncedLyrics('Title', 'Artist');

      expect(result, lyrics);
      verify(() => mockLyrics.fetchLyrics(any(), any())).called(1);
      verify(() => mockNetease.fetchSyncedLyrics(any(), any())).called(1);
    });
  });
}
