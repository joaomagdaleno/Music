import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:music_tag_editor/models/metadata_models.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:music_tag_editor/services/startup_logger.dart';

class MetadataEmbedder {
  final _deps = DependencyManager.instance;

  /// Embed metadata into an audio file using FFmpeg.
  Future<bool> embed(
    String audioPath,
    AggregatedMetadata metadata, {
    String? lyrics,
  }) async {
    try {
      final ext = p.extension(audioPath);
      final dir = p.dirname(audioPath);
      final base = p.basenameWithoutExtension(audioPath);
      final tempPath = p.join(dir, '${base}_tagged$ext');

      final args = <String>[
        '-y',
        '-i',
        audioPath,
        '-c',
        'copy',
      ];

      // Add metadata tags
      if (metadata.title != null) {
        args.addAll(['-metadata', 'title=${metadata.title}']);
      }
      if (metadata.artist != null) {
        args.addAll(['-metadata', 'artist=${metadata.artist}']);
      }
      if (metadata.album != null) {
        args.addAll(['-metadata', 'album=${metadata.album}']);
      }
      if (metadata.genre != null) {
        args.addAll(['-metadata', 'genre=${metadata.genre}']);
      }
      if (metadata.year != null) {
        args.addAll(['-metadata', 'date=${metadata.year}']);
      }
      
      if (lyrics != null) {
        // Embed USLT (Unsynchronized Lyrics)
        args.addAll(['-metadata', 'lyrics=$lyrics']);
      }

      args.add(tempPath);

      StartupLogger.log('[MetadataEmbedder] Running FFmpeg for: $base');
      final result = await Process.run(_deps.ffmpegPath, args);

      if (result.exitCode == 0) {
        // Replace original with tagged version
        await File(audioPath).delete();
        await File(tempPath).rename(audioPath);
        return true;
      }

      StartupLogger.log('[MetadataEmbedder] FFmpeg failed: ${result.stderr}');
      
      // Clean up temp file if it exists
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      return false;
    } catch (e) {
      StartupLogger.log('[MetadataEmbedder] Error: $e');
      return false;
    }
  }
}
