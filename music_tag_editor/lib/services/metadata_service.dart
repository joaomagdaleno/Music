import 'dart:io';
import 'dart:typed_data';
import 'package:music_tag_editor/src/rust/api/metadata.dart' as rust;
import 'package:music_tag_editor/src/rust/api/metadata.dart' show AudioMetadata;

class MetadataService {
  static final MetadataService _instance = MetadataService._internal();
  static MetadataService get instance => _instance;
  MetadataService._internal();

  Future<Map<String, dynamic>> readMetadata(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }

    try {
      final metadata = await rust.readMetadata(path: filePath);
      return {
        'title': metadata.title ?? 'Unknown Title',
        'artist': metadata.artist ?? 'Unknown Artist',
        'album': metadata.album ?? 'Unknown Album',
        'track': metadata.trackNumber ?? 0,
        'genre': metadata.genre ?? 'Unknown Genre',
        'duration_ms': metadata.durationMs,
        'path': metadata.filePath,
      };
    } catch (e) {
      throw Exception('Failed to read metadata via Rust: $e');
    }
  }

  Future<Uint8List?> extractCoverArt(String filePath) async {
    try {
      final bytes = await rust.extractCoverArt(path: filePath);
      return bytes != null ? Uint8List.fromList(bytes) : null;
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List?> extractAndOptimizeCover(String filePath, {int maxSize = 500}) async {
    try {
      final bytes = await rust.extractAndOptimizeCover(path: filePath, maxSize: maxSize);
      return bytes != null ? Uint8List.fromList(bytes) : null;
    } catch (e) {
      return null;
    }
  }
}
