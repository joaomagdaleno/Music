@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:music_hub/api/netease_api.dart';
import 'package:music_hub/features/player/services/lyrics_service.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late NeteaseApi api;
  late MockHttpClient mockClient;

  setUp(() {
    mockClient = MockHttpClient();
    api = NeteaseApi(client: mockClient);
    registerFallbackValue(Uri());
  });

  group('NeteaseApi', () {
    test('fetchSyncedLyrics returns list on query', () async {
      final mockResponse = {
        'result': {
          'songs': [
            {'id': 123}
          ]
        }
      };
      final mockLyricsResponse = {
        'lrc': {'lyric': '[00:00.00] Test Lyric'}
      };

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((invocation) async {
        final uri = invocation.positionalArguments[0] as Uri;
        if (uri.path.contains('search')) {
          return http.Response(jsonEncode(mockResponse), 200);
        } else {
          return http.Response(jsonEncode(mockLyricsResponse), 200);
        }
      });

      final result = await api.fetchSyncedLyrics('test', 'test');
      expect(result, isA<List<LyricLine>>());
      expect(result.first.text, 'Test Lyric');
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
