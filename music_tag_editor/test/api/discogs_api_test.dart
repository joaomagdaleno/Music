import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:music_tag_editor/api/discogs_api.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late DiscogsApi api;
  late MockHttpClient mockClient;

  setUp(() {
    mockClient = MockHttpClient();
    api = DiscogsApi(client: mockClient);
    registerFallbackValue(Uri());
  });

  group('DiscogsApi', () {
    test('searchRelease returns parsed data on success', () async {
      final mockResponse = {
        'results': [
          {
            'title': 'Release Title',
            'year': '2023',
            'label': ['Label Name'],
            'genre': ['Rock'],
            'style': ['Alternative'],
            'thumb': 'thumb.jpg',
            'cover_image': 'cover.jpg',
          }
        ]
      };

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
              (_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await api.searchRelease('Title', 'Artist');

      expect(result, isNotNull);
      expect(result!['title'], 'Release Title');
      expect(result['year'], '2023');
      expect(result['label'], 'Label Name');
      expect(result['genre'], 'Rock');
    });

    test('searchRelease returns null on empty results', () async {
      final mockResponse = {'results': []};

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
              (_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await api.searchRelease('Title', 'Artist');

      expect(result, isNull);
    });

    test('searchRelease handles errors gracefully', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenThrow(Exception('Network error'));

      final result = await api.searchRelease('Title', 'Artist');

      expect(result, isNull);
    });
  });
}
