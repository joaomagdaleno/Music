import 'package:flutter_test/flutter_test.dart';
import 'package:music_tag_editor/api/lastfm_api.dart';

void main() {
  group('LastFmApi', () {
    late LastFmApi api;

    setUp(() {
      api = LastFmApi();
    });

    test('getTrackInfo returns null when API key is placeholder', () async {
      final result = await api.getTrackInfo('Song', 'Artist');
      // Returns null because API key is placeholder
      expect(result, isNull);
    });

    test('getTrackInfo handles empty strings', () async {
      final result = await api.getTrackInfo('', '');
      expect(result, isNull);
    });

    test('LastFmApi can be instantiated', () {
      expect(api, isNotNull);
      expect(api, isA<LastFmApi>());
    });
  });
}
