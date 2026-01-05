import 'dart:io';
import 'package:music_tag_editor/models/search_models.dart';
import 'package:music_tag_editor/models/download_models.dart';
import 'package:music_tag_editor/models/metadata_models.dart';
import 'package:music_tag_editor/services/download/download_provider.dart';
import 'package:music_tag_editor/services/download/youtube_download_provider.dart';
import 'package:music_tag_editor/services/download/metadata_embedder.dart';
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
        onProgress?.call(0.1, 'Downloading...');
        final downloadedPath = await provider.download(url, format, onProgress: (p) => onProgress?.call(p, 'Downloading...'));
        
        onProgress?.call(0.8, 'Moving to final directory...');
        final fileName = p.basename(downloadedPath);
        final finalPath = p.join(outputDir, fileName);
        
        await File(downloadedPath).copy(finalPath);
        await File(downloadedPath).delete();
        
        onProgress?.call(1.0, 'Complete!');
        return finalPath;
      }
    }
    throw Exception('No provider found for URL: $url');
  }

  /// Helper to embed metadata using extracted embedder.
  Future<bool> embedMetadata(String audioPath, AggregatedMetadata metadata, {String? lyrics}) async => await _embedder.embed(audioPath, metadata, lyrics: lyrics);
}
