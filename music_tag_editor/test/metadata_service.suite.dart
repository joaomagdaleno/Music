@Tags(['unit'])
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_tag_editor/services/metadata_service.dart';

void main() {
  group('MetadataService Tests', () {
    late MetadataService metadataService;
    late File tempFile;

    setUp(() async {
      metadataService = MetadataService();
      tempFile = File('test_metadata.mp3');
      // Create a dummy file with some content to avoid "File not found" or empty file issues
      await tempFile.writeAsBytes(List.generate(100, (i) => i));
    });

    tearDown(() async {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });

    test('Read and Write Metadata', () async {
      await metadataService.writeMetadata(
        tempFile.path,
        title: 'Test Title',
        artist: 'Test Artist',
        album: 'Test Album',
        trackNumber: 5,
      );

      final metadata = await metadataService.readMetadata(tempFile.path);

      expect(metadata['title'], 'Test Title');
      expect(metadata['artist'], 'Test Artist');
      expect(metadata['album'], 'Test Album');
      expect(metadata['track'], 5);
      expect(metadata['genre'], 'Unknown Genre'); // Default
    });

    test('Read non-existent file throws exception', () async {
      expect(
        () => metadataService.readMetadata('non_existent.mp3'),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('Write to non-existent file throws exception', () async {
      expect(
        () => metadataService.writeMetadata(
          'non_existent.mp3',
          title: '',
          artist: '',
          album: '',
          trackNumber: 0,
        ),
        throwsA(isA<FileSystemException>()),
      );
    });
  });
}

