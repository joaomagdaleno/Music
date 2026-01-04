import 'dart:io';
import 'package:dart_tags/dart_tags.dart';

/// Service for reading and writing audio metadata using pure Dart.
/// Supports ID3v1 and ID3v2 tags for MP3 files.
import 'package:flutter/foundation.dart';

/// Service for reading and writing audio metadata using pure Dart.
/// Supports ID3v1 and ID3v2 tags for MP3 files.
class MetadataService {
  /// Reads metadata from an audio file.
  /// Returns a map with keys: title, artist, album, track
  // ⚡ Bolt: Offload heavy I/O and parsing to background isolate
  Future<Map<String, dynamic>> readMetadata(String filePath) =>
      compute(_readMetadataIsolate, filePath);

  /// Writes metadata to an audio file.
  Future<void> writeMetadata(
    String filePath, {
    required String title,
    required String artist,
    required String album,
    required int trackNumber,
    String? genre,
    int? year,
    String? lyrics,
  }) async {
    // ⚡ Bolt: Offload heavy I/O and parsing to background isolate
    final args = _WriteMetadataArgs(
      filePath: filePath,
      title: title,
      artist: artist,
      album: album,
      trackNumber: trackNumber,
      genre: genre,
      year: year,
      lyrics: lyrics,
    );
    await compute(_writeMetadataIsolate, args);
  }

  /// Parses track number from various formats (e.g., "5", "5/12")
  @visibleForTesting
  int parseTrackNumber(dynamic value) {
    if (value == null) {
      return 0;
    }
    final str = value.toString();
    // Handle "track/total" format like "5/12"
    final parts = str.split('/');
    return int.tryParse(parts.first.trim()) ?? 0;
  }
}

// ⚡ Bolt: Top-level function for compute
Future<Map<String, dynamic>> _readMetadataIsolate(String filePath) async {
  final file = File(filePath);
  if (!await file.exists()) {
    throw FileSystemException('File not found', filePath);
  }

  // Note: TagProcessor is lightweight to instantiate
  final tagProcessor = TagProcessor();
  final bytes = await file.readAsBytes();
  final tags = await tagProcessor.getTagsFromByteArray(
    Future.value(bytes.toList()),
  );

  // Prefer ID3v2 tags over ID3v1 if available
  final tag = tags.firstWhere(
    (t) => t.type == 'ID3' && t.version?.startsWith('2') == true,
    orElse: () => tags.isNotEmpty ? tags.first : Tag(),
  );

  final service = MetadataService();
  return {
    'title': tag.tags['title'] ?? tag.tags['TIT2'] ?? 'Unknown Title',
    'artist': tag.tags['artist'] ?? tag.tags['TPE1'] ?? 'Unknown Artist',
    'album': tag.tags['album'] ?? tag.tags['TALB'] ?? 'Unknown Album',
    'track': service.parseTrackNumber(tag.tags['track'] ?? tag.tags['TRCK']),
    'genre': tag.tags['genre'] ?? tag.tags['TCON'] ?? 'Unknown Genre',
    'lyrics': tag.tags['lyrics'] ??
        tag.tags['USLT'] ??
        tag.tags['unsynchronized_lyrics'],
  };
}

// ⚡ Bolt: Top-level function for compute
Future<void> _writeMetadataIsolate(_WriteMetadataArgs args) async {
  final file = File(args.filePath);
  if (!await file.exists()) {
    throw FileSystemException('File not found', args.filePath);
  }

  final tagProcessor = TagProcessor();
  final bytes = await file.readAsBytes();

  // Create ID3v2.4 tag with the new metadata
  final tag = Tag()
    ..type = 'ID3'
    ..version = '2.4.0'
    ..tags = {
      'title': args.title,
      'artist': args.artist,
      'album': args.album,
      'track': args.trackNumber.toString(),
      if (args.genre != null) 'genre': args.genre,
      if (args.year != null) 'year': args.year.toString(),
      if (args.lyrics != null) 'lyrics': args.lyrics,
      // ID3v2 frame IDs
      'TIT2': args.title,
      'TPE1': args.artist,
      'TALB': args.album,
      'TRCK': args.trackNumber.toString(),
      if (args.genre != null) 'TCON': args.genre,
      if (args.year != null) 'TDRC': args.year.toString(),
      if (args.year != null) 'TYER': args.year.toString(),
      if (args.lyrics != null) 'USLT': args.lyrics,
    };

  // Write the tags to the byte array
  final newBytes = await tagProcessor.putTagsToByteArray(
    Future.value(bytes.toList()),
    [tag],
  );

  // Write the modified bytes back to the file
  await file.writeAsBytes(newBytes);
}

// ⚡ Bolt: Arguments class for write isolate
class _WriteMetadataArgs {
  final String filePath;
  final String title;
  final String artist;
  final String album;
  final int trackNumber;
  final String? genre;
  final int? year;
  final String? lyrics;

  _WriteMetadataArgs({
    required this.filePath,
    required this.title,
    required this.artist,
    required this.album,
    required this.trackNumber,
    this.genre,
    this.year,
    this.lyrics,
  });
}
