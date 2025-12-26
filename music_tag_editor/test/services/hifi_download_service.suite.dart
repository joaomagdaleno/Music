@Tags(['unit'])
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/api/slavart_api.dart';
import 'package:music_tag_editor/services/hifi_download_service.dart';

class MockSlavArtApi extends Mock implements SlavArtApi {}

class FakeFile extends Fake implements File {
  @override
  String get path => '/tmp/test.flac';
}

void main() {
  late HiFiDownloadService service;
  late MockSlavArtApi mockSlavArt;

  setUp(() {
    mockSlavArt = MockSlavArtApi();
    service = HiFiDownloadService.test(slavArt: mockSlavArt);
  });

  group('HiFiDownloadService', () {
    test('search returns sorted results', () async {
      final mockResults = [
        SlavArtResult(
            id: '1',
            title: 'Song',
            artist: 'Artist',
            album: 'Album',
            source: 'tidal',
            url: 'url1',
            quality: '16-bit'),
        SlavArtResult(
            id: '2',
            title: 'Song',
            artist: 'Artist',
            album: 'Album',
            source: 'qobuz',
            url: 'url2',
            quality: '24-bit'),
      ];

      when(() => mockSlavArt.search(any()))
          .thenAnswer((_) async => mockResults);

      final results = await service.search('query');

      expect(results.length, 2);
      expect(results.first.quality, '24-bit'); // Higher quality first
      expect(results.last.quality, '16-bit');
    });

    test('download handles success', () async {
      final result = HiFiSearchResult(
        id: '1',
        title: 'Title',
        artist: 'Artist',
        source: HiFiSource.qobuz,
        sourceUrl: 'url',
        quality: 'FLAC',
      );

      when(() => mockSlavArt.getDownloadUrl(any()))
          .thenAnswer((_) async => 'http://download.link');
      when(() => mockSlavArt.downloadFlac(any(), any(),
              onProgress: any(named: 'onProgress')))
          .thenAnswer((_) async => FakeFile());

      final file = await service.download(result, '/downloads');

      expect(file, isNotNull);
      verify(() => mockSlavArt.getDownloadUrl('url')).called(1);
    });

    test('download handles failure to get link', () async {
      final result = HiFiSearchResult(
        id: '1',
        title: 'Title',
        artist: 'Artist',
        source: HiFiSource.qobuz,
        sourceUrl: 'url',
        quality: 'FLAC',
      );

      when(() => mockSlavArt.getDownloadUrl(any()))
          .thenAnswer((_) async => null);

      final file = await service.download(result, '/downloads');

      expect(file, isNull);
    });

    test('findHiFiVersion finds match', () async {
      final mockResults = [
        SlavArtResult(
            id: '1',
            title: 'Test Song',
            artist: 'Test Artist',
            source: 'tidal',
            url: 'url1'),
      ];
      when(() => mockSlavArt.search(any()))
          .thenAnswer((_) async => mockResults);

      final result = await service.findHiFiVersion('Test Song', 'Test Artist');

      expect(result, isNotNull);
      expect(result?.title, 'Test Song');
    });
  });
}
