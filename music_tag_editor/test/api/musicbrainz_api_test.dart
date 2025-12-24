import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:music_tag_editor/api/musicbrainz_api.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MusicBrainzApi api;
  late MockHttpClient mockClient;

  setUp(() {
    mockClient = MockHttpClient();
    api = MusicBrainzApi(client: mockClient);
    registerFallbackValue(Uri());
  });

  group('MusicBrainzApi', () {
    test('searchMetadata returns parsed recordings', () async {
      final mockResponse = {
        'recordings': [
          {
            'id': '123',
            'title': 'Song Title',
            'artist-credit': [
              {'name': 'Artist Name'}
            ],
            'releases': [
              {'title': 'Album Name'}
            ],
            'tags': [
              {'name': 'rock'}
            ]
          }
        ]
      };

      // Match header requirement
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
              (_) async => http.Response(jsonEncode(mockResponse), 200));

      final results = await api.searchMetadata('Song Title', 'Artist Name');

      expect(results, isNotEmpty);
      expect(results.first['title'], 'Song Title');
      expect(results.first['artist'], 'Artist Name');
      expect(results.first['genres'], contains('rock'));
    });

    test('searchMetadata returns empty list on error response', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('Error', 500));

      final results = await api.searchMetadata('Song Title', 'Artist Name');

      expect(results, isEmpty);
    });
  });
}
