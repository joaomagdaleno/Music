@Tags(['unit'])
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:music_tag_editor/api/genius_api.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late GeniusApi api;
  late MockHttpClient mockClient;

  setUp(() {
    mockClient = MockHttpClient();
    api = GeniusApi(client: mockClient);
    registerFallbackValue(Uri());
  });

  group('GeniusApi', () {
    test('searchSong returns parsed data on success', () async {
      final mockResponse = {
        'response': {
          'hits': [
            {
              'result': {
                'id': 123,
                'title': 'Song Title',
                'primary_artist': {'name': 'Artist Name'},
                'song_art_image_thumbnail_url': 'thumb.jpg',
                'url': 'http://genius.com/song'
              }
            }
          ]
        }
      };

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
              (_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await api.searchSong('Title', 'Artist');

      expect(result, isNotNull);
      expect(result!['title'], 'Song Title');
      expect(result['artist'], 'Artist Name');
      expect(result['id'], 123);
    });

    test('searchSong returns null on empty hits', () async {
      final mockResponse = {
        'response': {'hits': []}
      };

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
              (_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await api.searchSong('Title', 'Artist');

      expect(result, isNull);
    });

    test('searchSong handles errors gracefully', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(Exception('Network error'));

      final result = await api.searchSong('Title', 'Artist');

      expect(result, isNull);
    });
  });
}
