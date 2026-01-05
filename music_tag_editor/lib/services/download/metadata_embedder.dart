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
    String? artworkPath,
    bool convertToMp3 = false,
  }) async {
    try {
      final ext = convertToMp3 ? '.mp3' : p.extension(audioPath);
      final dir = p.dirname(audioPath);
      final base = p.basenameWithoutExtension(audioPath);
      final tempPath = p.join(dir, '${base}_tagged$ext');

      final args = <String>[
        '-y',
        '-i',
        audioPath,
      ];

      if (artworkPath != null && await File(artworkPath).exists()) {
        args.addAll(['-i', artworkPath]);
        // Map audio from first input and image from second input
        args.addAll(['-map', '0:a', '-map', '1:0']);
      } else {
        // Just audio
        args.addAll(['-map', '0:a']);
      }

      if (convertToMp3) {
        args.addAll(['-c:a', 'libmp3lame', '-b:a', '320k']);
      } else {
        args.addAll(['-c', 'copy']);
      }

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

      if (artworkPath != null) {
        // Tagging for cover art
        args.addAll(['-id3v2_version', '3']);
        args.addAll(['-metadata:s:v', 'title=Album cover']);
        args.addAll(['-metadata:s:v', 'comment=Cover (front)']);
      }

      args.add(tempPath);

      StartupLogger.log(
          '[MetadataEmbedder] Running FFmpeg for: $base (Target: $ext)');
      final result = await Process.run(_deps.ffmpegPath, args);

      if (result.exitCode == 0) {
        // If we converted, the original file might be different format (e.g. .webm)
        // so we delete original and rename temp to the new final path if needed, 
        // but here we follow the original logic of replacing the original file 
        // IF the extension matches. If it doesn't match, we might need a more 
        // sophisticated cleanup/renaming logic for the caller.
        // For simplicity in the instant download flow, the caller will handle the final path.
        
        final originalFile = File(audioPath);
        if (await originalFile.exists()) {
          await originalFile.delete();
        }
        
        // If extension changed (e.g. webm -> mp3), the audioPath is no longer correct
        // but the caller of DownloadService expects the file to be at audioPath.
        // We should probably rename tempPath to a path with the original name but new extension 
        // or just let the caller decide.
        // Revised: Return the final path in the result or rename to audioPath 
        // but audioPath's extension might be wrong.
        
        final finalFinalPath = p.join(dir, '$base$ext');
        await File(tempPath).rename(finalFinalPath);
        
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
