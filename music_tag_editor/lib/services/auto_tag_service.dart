import 'dart:io';
import 'package:music_tag_editor/services/metadata_aggregator_service.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';

/// Service for automatic metadata tagging using audio fingerprinting.
class AutoTagService {
  static final AutoTagService instance = AutoTagService._internal();
  AutoTagService._internal();

  final _aggregator = MetadataAggregatorService.instance;
  final _deps = DependencyManager.instance;

  /// Auto-tag a local audio file using fingerprint identification.
  /// Returns the identified metadata or null if identification failed.
  Future<AutoTagResult> autoTag(
    String filePath, {
    void Function(String status)? onStatus,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return AutoTagResult(success: false, error: 'File not found');
    }

    onStatus?.call('Generating audio fingerprint...');

    // Use MetadataAggregatorService which already has fingerprint logic
    final metadata = await _aggregator.identifyByFingerprint(filePath);

    if (metadata == null) {
      return AutoTagResult(
        success: false,
        error: 'Could not identify track',
      );
    }

    onStatus?.call('Found: ${metadata.artist} - ${metadata.title}');

    // Fetch additional metadata if we got a match
    if (metadata.title != null && metadata.artist != null) {
      onStatus?.call('Fetching additional metadata...');

      final fullMetadata = await _aggregator.aggregateMetadata(
        metadata.title!,
        metadata.artist!,
      );

      onStatus?.call('Embedding metadata into file...');

      // Embed metadata using FFmpeg
      final success = await _embedMetadata(filePath, fullMetadata);

      if (success) {
        onStatus?.call('Auto-tagging complete!');
        return AutoTagResult(
          success: true,
          metadata: fullMetadata,
        );
      } else {
        return AutoTagResult(
          success: true,
          metadata: fullMetadata,
          warning: 'Identified but could not embed metadata',
        );
      }
    }

    return AutoTagResult(
      success: true,
      metadata: metadata,
    );
  }

  /// Embed metadata into an audio file using FFmpeg.
  Future<bool> _embedMetadata(String filePath, AggregatedMetadata meta) async {
    try {
      final ext = filePath.split('.').last.toLowerCase();
      final tempPath = '${filePath}_tagged.$ext';

      final args = <String>[
        '-y',
        '-i',
        filePath,
        '-c',
        'copy',
      ];

      // Add metadata tags
      if (meta.title != null) {
        args.addAll(['-metadata', 'title=${meta.title}']);
      }
      if (meta.artist != null) {
        args.addAll(['-metadata', 'artist=${meta.artist}']);
      }
      if (meta.album != null) {
        args.addAll(['-metadata', 'album=${meta.album}']);
      }
      if (meta.genre != null) {
        args.addAll(['-metadata', 'genre=${meta.genre}']);
      }
      if (meta.year != null) {
        args.addAll(['-metadata', 'date=${meta.year}']);
      }

      args.add(tempPath);

      final result = await Process.run(_deps.ffmpegPath, args);

      if (result.exitCode == 0) {
        // Replace original with tagged version
        await File(filePath).delete();
        await File(tempPath).rename(filePath);
        return true;
      }

      // Clean up temp file if it exists
      final tempFile = File(tempPath);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Batch auto-tag multiple files.
  Future<List<AutoTagResult>> batchAutoTag(
    List<String> filePaths, {
    void Function(int current, int total, String status)? onProgress,
  }) async {
    final results = <AutoTagResult>[];

    for (int i = 0; i < filePaths.length; i++) {
      onProgress?.call(
          i + 1, filePaths.length, 'Processing ${i + 1}/${filePaths.length}');

      final result = await autoTag(filePaths[i]);
      results.add(result);

      // Small delay to avoid overwhelming APIs
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return results;
  }
}

/// Result of an auto-tag operation.
class AutoTagResult {
  final bool success;
  final AggregatedMetadata? metadata;
  final String? error;
  final String? warning;

  AutoTagResult({
    required this.success,
    this.metadata,
    this.error,
    this.warning,
  });
}


