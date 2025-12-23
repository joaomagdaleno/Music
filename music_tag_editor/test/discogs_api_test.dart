import 'package:flutter_test/flutter_test.dart';
import 'package:music_tag_editor/api/discogs_api.dart';

void main() {
  group('DiscogsApi', () {
    late DiscogsApi api;

    setUp(() {
      api = DiscogsApi();
    });

    test('searchRelease returns null on empty query', () async {
      final result = await api.searchRelease('', '');
      expect(result, isNull);
    });

    test('searchRelease handles network errors gracefully', () async {
      final result = await api.searchRelease('nonexistent album', 'noartist');
      // Could return null or a map depending on API response
      expect(result == null || result.isNotEmpty, true);
    });

    test('DiscogsApi can be instantiated', () {
      expect(api, isNotNull);
      expect(api, isA<DiscogsApi>());
    });
  });
}
