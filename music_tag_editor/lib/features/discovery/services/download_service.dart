import 'dart:io';
import 'package:music_hub/models/search_models.dart';
import 'package:music_hub/models/download_models.dart';
import 'package:music_hub/features/library/models/metadata_models.dart';
import 'package:music_hub/features/discovery/services/download/download_provider.dart';
import 'package:music_hub/features/discovery/services/download/youtube_download_provider.dart';
import 'package:music_hub/features/discovery/services/download/metadata_embedder.dart';
import 'package:music_hub/features/library/services/metadata_aggregator_service.dart';
import 'package:music_hub/core/services/startup_logger.dart';
import 'package:path/path.dart' as p;

/// Service for downloading music from various platforms.
class DownloadService {
  static DownloadService? _instance;
  static DownloadService get instance =>
      _instance ??= DownloadService._internal();
  static set instance(DownloadService value) => _instance = value;
  static void resetInstance() => _instance = null;

  DownloadService._internal();

  final List<DownloadProvider> _providers = [
    YouTubeDownloadProvider(),
  ];

  final MetadataEmbedder _embedder = MetadataEmbedder();

  /// Detect platform from URL.
  static MediaPlatform detectPlatform(String url) {
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      if (url.contains('music.youtube.com')) {
        return MediaPlatform.youtubeMusic;
      }
      return MediaPlatform.youtube;
    } else if (url.contains('tidal.com') ||
        url.contains('deezer.com') ||
        url.contains('qobuz.com')) {
      return MediaPlatform.hifi;
    }
    return MediaPlatform.unknown;
  }

  /// Get media info and available formats.
  Future<MediaInfo> getMediaInfo(String url) async {
    final platform = detectPlatform(url);
    for (var provider in _providers) {
      if (provider.supports(url, platform)) {
        return await provider.getInfo(url);
      }
    }
    throw Exception('No provider found for URL: $url');
  }

  /// Download media with selected format.
  Future<String> download(
    String url,
    DownloadFormat format,
    String outputDir, {
    void Function(double progress, String status)? onProgress,
    String? overrideThumbnailUrl,
    String? title,
    String? artist,
  }) async {
    final platform = detectPlatform(url);

    for (var provider in _providers) {
      if (provider.supports(url, platform)) {
        // Enforce metadata enrichment before download if possible
        AggregatedMetadata? enriched;
        if (title != null && artist != null) {
          onProgress?.call(0.05, 'Buscando metadados oficiais...');
          try {
            enriched = await MetadataAggregatorService.instance
                .aggregateMetadata(title, artist);
          } catch (e) {
            StartupLogger.log('[DownloadService] Enrichment failed: $e');
          }
        }

        onProgress?.call(0.1, 'Descarregando áudio...');
        final downloadedPath = await provider.download(url, format,
            onProgress: (p) => onProgress?.call(p, 'Baixando...'));

        onProgress?.call(0.8, 'Organizando arquivos...');
        final ext = p.extension(downloadedPath);
        final safeTitle = (enriched?.title ?? title ?? 'Unknown')
            .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
        final safeArtist = (enriched?.artist ?? artist ?? 'Unknown')
            .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

        final finalFileName = '$safeArtist - $safeTitle$ext';
        final finalPath = p.join(outputDir, finalFileName);

        // Copy and ensure path exists
        final targetFile = File(finalPath);
        if (!await targetFile.parent.exists()) {
          await targetFile.parent.create(recursive: true);
        }
        await File(downloadedPath).copy(finalPath);
        await File(downloadedPath).delete();

        if (enriched != null) {
          onProgress?.call(0.9, 'Embutindo capa e tags...');
          await embedMetadata(finalPath, enriched);
        }

        onProgress?.call(1.0, 'Concluído!');
        return finalPath;
      }
    }
    throw Exception('No provider found for URL: $url');
  }

  /// Helper to embed metadata using extracted embedder.
  Future<bool> embedMetadata(String audioPath, AggregatedMetadata metadata,
          {String? lyrics}) async =>
      await _embedder.embed(audioPath, metadata, lyrics: lyrics);
}
