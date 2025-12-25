@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:music_tag_editor/api/musicbrainz_api.dart';

void main() {
  group('MusicBrainzApi', () {
    late MusicBrainzApi api;

    setUp(() {
      api = MusicBrainzApi();
    });

    test('searchRecording returns map on query', () async {
      final result = await api.searchRecording(title: 'test', artist: 'test');
      expect(result, isA<Map<String, dynamic>>());
    });

    test('searchRecording handles empty strings', () async {
      final result = await api.searchRecording(title: '', artist: '');
      expect(result, isA<Map<String, dynamic>>());
    });

    test('MusicBrainzApi can be instantiated', () {
      expect(api, isNotNull);
      expect(api, isA<MusicBrainzApi>());
    });
  });
}
