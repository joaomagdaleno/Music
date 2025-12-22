import 'dart:io';
import 'package:dart_tags/dart_tags.dart';

/// Service for reading and writing audio metadata using pure Dart.
/// Supports ID3v1 and ID3v2 tags for MP3 files.
class MetadataService {
  final TagProcessor _tagProcessor = TagProcessor();

  /// Reads metadata from an audio file.
  /// Returns a map with keys: title, artist, album, track
  Future<Map<String, dynamic>> readMetadata(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }

    final bytes = await file.readAsBytes();
    final tags = await _tagProcessor.getTagsFromByteArray(
      Future.value(bytes.toList()),
    );

    // Prefer ID3v2 tags over ID3v1 if available
    final tag = tags.firstWhere(
      (t) => t.type == 'ID3' && t.version?.startsWith('2') == true,
      orElse: () => tags.isNotEmpty ? tags.first : Tag(),
    );

    return {
      'title': tag.tags['title'] ?? tag.tags['TIT2'] ?? 'Unknown Title',
      'artist': tag.tags['artist'] ?? tag.tags['TPE1'] ?? 'Unknown Artist',
      'album': tag.tags['album'] ?? tag.tags['TALB'] ?? 'Unknown Album',
      'track': _parseTrackNumber(tag.tags['track'] ?? tag.tags['TRCK']),
      'genre': tag.tags['genre'] ?? tag.tags['TCON'] ?? 'Unknown Genre',
    };
  }

  /// Writes metadata to an audio file.
  Future<void> writeMetadata(
    String filePath, {
    required String title,
    required String artist,
    required String album,
    required int trackNumber,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }

    final bytes = await file.readAsBytes();

    // Create ID3v2.4 tag with the new metadata
    final tag = Tag()
      ..type = 'ID3'
      ..version = '2.4.0'
      ..tags = {
        'title': title,
        'artist': artist,
        'album': album,
        'track': trackNumber.toString(),
        // ID3v2 frame IDs
        'TIT2': title,
        'TPE1': artist,
        'TALB': album,
        'TRCK': trackNumber.toString(),
      };

    // Write the tags to the byte array
    final newBytes = await _tagProcessor.putTagsToByteArray(
      Future.value(bytes.toList()),
      [tag],
    );

    // Write the modified bytes back to the file
    await file.writeAsBytes(newBytes);
  }

  /// Parses track number from various formats (e.g., "5", "5/12")
  int _parseTrackNumber(dynamic value) {
    if (value == null) { return 0; }
    final str = value.toString();
    // Handle "track/total" format like "5/12"
    final parts = str.split('/');
    return int.tryParse(parts.first.trim()) ?? 0;
  }
}
