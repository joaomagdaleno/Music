import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:music_tag_editor/api/lastfm_api.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late LastFmApi api;
  late MockHttpClient mockClient;

  setUp(() {
    mockClient = MockHttpClient();
    api = LastFmApi(client: mockClient, apiKey: 'TEST_KEY');
    registerFallbackValue(Uri());
  });

  group('LastFmApi', () {
    test('getTrackInfo returns parsed data on success', () async {
      final mockResponse = {
        'track': {
          'name': 'Song Title',
          'artist': {'name': 'Artist Name'},
          'album': {'title': 'Album Name'},
          'toptags': {
            'tag': [
              {'name': 'rock'},
              {'name': 'pop'}
            ]
          }
        }
      };

      when(() => mockClient.get(any())).thenAnswer(
          (_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await api.getTrackInfo('Song Title', 'Artist Name');

      expect(result, isNotNull);
      expect(result!['title'], 'Song Title');
      expect(result['artist'], 'Artist Name');
      expect(result['album'], 'Album Name');
      expect(result['genres'], contains('rock'));
    });

    test('getTrackInfo returns null on error', () async {
      when(() => mockClient.get(any())).thenThrow(Exception('Network error'));

      final result = await api.getTrackInfo('Song Title', 'Artist Name');

      expect(result, isNull);
    });

    test('getTrackInfo returns null on 404', () async {
      when(() => mockClient.get(any()))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      final result = await api.getTrackInfo('Song Title', 'Artist Name');

      expect(result, isNull);
    });
  });
}
