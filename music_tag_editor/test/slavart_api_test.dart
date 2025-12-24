@Tags(['unit'])
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:music_tag_editor/api/slavart_api.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late SlavArtApi api;
  late MockHttpClient mockClient;

  setUp(() {
    mockClient = MockHttpClient();
    api = SlavArtApi(client: mockClient);

    registerFallbackValue(Uri());
    registerFallbackValue(http.Request('GET', Uri()));
  });

  group('SlavArtApi', () {
    test('search returns parsed results on success', () async {
      final mockResponse = {
        'qobuz': [
          {'id': 'q1', 'title': 'Q Song', 'artist': 'Q Artist'}
        ],
        'tidal': [],
        'deezer': []
      };

      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
              (_) async => http.Response(jsonEncode(mockResponse), 200));

      final results = await api.search('query');

      expect(results.length, 1);
      expect(results[0].title, 'Q Song');
      expect(results[0].source, 'qobuz');
    });

    test('getDownloadUrl returns URL on success', () async {
      when(() => mockClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async =>
              http.Response(jsonEncode({'download_url': 'http://dl'}), 200));

      final url = await api.getDownloadUrl('http://origin');
      expect(url, 'http://dl');
    });

    test('downloadFlac streams content to file', () async {
      await IOOverrides.runZoned(() async {
        final mockStreamResponse = http.StreamedResponse(
          Stream.fromIterable([utf8.encode('flac content')]),
          200,
          contentLength: 12,
          headers: {'content-disposition': 'attachment; filename="song.flac"'},
        );

        when(() => mockClient.send(any()))
            .thenAnswer((_) async => mockStreamResponse);

        final result = await api.downloadFlac('http://dl', '/dir');

        expect(result, isNotNull);
        expect(result!.path, contains('song.flac'));
      }, createFile: (path) => _MockFile(path));
    });
  });
}

class _MockFile extends Fake implements File {
  @override
  final String path;
  _MockFile(this.path);

  @override
  IOSink openWrite(
          {FileMode mode = FileMode.write,
          bool append = false,
          Encoding encoding = utf8}) =>
      _MockIOSink();
}

class _MockIOSink extends Fake implements IOSink {
  @override
  void add(List<int> data) {}
  @override
  Future<void> close() async {}
}
