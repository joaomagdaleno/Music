@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:music_hub/api/musicbrainz_api.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;

class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('MusicBrainzApi', () {
    late MusicBrainzApi api;
    late MockHttpClient client;

    setUpAll(() {
      registerFallbackValue(Uri());
    });

    setUp(() {
      client = MockHttpClient();
      api = MusicBrainzApi(client: client);
    });

    test('searchRecording returns map on query', () async {
      when(() => client.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('{"recordings": []}', 200));

      final result = await api.searchRecording(title: 'test', artist: 'test');
      expect(result, isA<Map<String, dynamic>>());
    });

    test('searchRecording handles empty strings', () async {
      when(() => client.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('{"recordings": []}', 200));

      final result = await api.searchRecording(title: '', artist: '');
      expect(result, isA<Map<String, dynamic>>());
    });

    test('MusicBrainzApi can be instantiated', () {
      expect(api, isNotNull);
      expect(api, isA<MusicBrainzApi>());
    });
  });
}
