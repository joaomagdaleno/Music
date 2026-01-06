import 'package:flutter_test/flutter_test.dart';
import 'package:music_hub/models/search_models.dart';

void main() {
  group('SearchResult.cleanMetadata', () {
    test('should remove (Official Video) suffixes', () {
      expect(SearchResult.cleanMetadata('Song (Official Video)'), 'Song');
      expect(SearchResult.cleanMetadata('Song [Official Video]'), 'Song');
    });

    test('should remove (Music Video) suffixes', () {
      expect(SearchResult.cleanMetadata('Song (Music Video)'), 'Song');
      expect(SearchResult.cleanMetadata('Song [Music Video]'), 'Song');
    });

    test('should remove (Video) and [Video] suffixes', () {
      expect(SearchResult.cleanMetadata('Song (Video)'), 'Song');
      expect(SearchResult.cleanMetadata('Song [Video]'), 'Song');
    });

    test('should remove (Lyrics) and [Lyrics] suffixes', () {
      expect(SearchResult.cleanMetadata('Song (Lyrics)'), 'Song');
      expect(SearchResult.cleanMetadata('Song [Lyrics]'), 'Song');
    });

    test('should preserve (feat. X) and (Live at Wembley)', () {
      expect(SearchResult.cleanMetadata('Song (feat. Artist)'), 'Song (feat. Artist)');
      expect(SearchResult.cleanMetadata('Song (Live at Wembley)'), 'Song (Live at Wembley)');
    });

    test('should clean trailing " - YouTube"', () {
      expect(SearchResult.cleanMetadata('Song Trailer - YouTube'), 'Song Trailer');
    });

    test('should trim whitespace after removal', () {
      expect(SearchResult.cleanMetadata('  Song (Official Video)  '), 'Song');
    });
  });

  group('SearchResult.toMatchKey (Normalization)', () {
    test('should normalize diacritics', () {
      expect(SearchResult.toMatchKey('Café'), 'cafe');
      expect(SearchResult.toMatchKey('Árbol'), 'arbol');
      expect(SearchResult.toMatchKey('Niño'), 'nino');
    });

    test('should lowercase and trim', () {
      expect(SearchResult.toMatchKey('  TITLE  '), 'title');
    });

    test('should handle mixed diacritics and casing', () {
      expect(SearchResult.toMatchKey('ÀñGèL (Remix)'), 'angel (remix)');
    });
  });
}
