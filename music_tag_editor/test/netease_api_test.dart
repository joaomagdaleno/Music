@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:music_tag_editor/api/netease_api.dart';
import 'package:music_tag_editor/services/lyrics_service.dart';

void main() {
  group('NeteaseApi', () {
    late NeteaseApi api;

    setUp(() {
      api = NeteaseApi();
    });

    test('fetchSyncedLyrics returns list on query', () async {
      final result = await api.fetchSyncedLyrics('test', 'test');
      expect(result, isA<List<LyricLine>>());
    });

    test('fetchSyncedLyrics handles empty strings', () async {
      final result = await api.fetchSyncedLyrics('', '');
      expect(result, isA<List<LyricLine>>());
    });

    test('NeteaseApi can be instantiated', () {
      expect(api, isNotNull);
      expect(api, isA<NeteaseApi>());
    });
  });
}
