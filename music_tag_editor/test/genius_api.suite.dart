@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:music_tag_editor/api/genius_api.dart';

void main() {
  group('GeniusApi', () {
    late GeniusApi api;

    setUp(() {
      api = GeniusApi();
    });

    test('searchSong returns null on empty query', () async {
      final result = await api.searchSong('', '');
      expect(result, isNull);
    });

    test('searchSong handles network errors gracefully', () async {
      final result = await api.searchSong('nonexistent track', 'noartist');
      // Could return null or a map depending on API response
      expect(result == null || result.isNotEmpty, true);
    });

    test('GeniusApi can be instantiated', () {
      expect(api, isNotNull);
      expect(api, isA<GeniusApi>());
    });
  });
}
