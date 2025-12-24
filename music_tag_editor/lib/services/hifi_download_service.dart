import 'dart:io';
import 'package:meta/meta.dart';
import 'package:music_tag_editor/api/slavart_api.dart';
import 'package:path/path.dart' as p;

/// Unified Hi-Fi download service with multiple sources.
class HiFiDownloadService {
  static HiFiDownloadService _instance = HiFiDownloadService._internal();
  static HiFiDownloadService get instance => _instance;

  @visibleForTesting
  static set instance(HiFiDownloadService mock) => _instance = mock;

  HiFiDownloadService._internal({SlavArtApi? slavArt})
      : _slavArt = slavArt ?? SlavArtApi();

  @visibleForTesting
  factory HiFiDownloadService.test({SlavArtApi? slavArt}) {
    return HiFiDownloadService._internal(slavArt: slavArt);
  }

  final SlavArtApi _slavArt;
  bool preferHiFi = true;

  /// Search for a track across all Hi-Fi platforms.
  Future<List<HiFiSearchResult>> search(String query) async {
    final results = <HiFiSearchResult>[];

    // Try SlavArt (covers Qobuz, Tidal, Deezer)
    try {
      final slavArtResults = await _slavArt.search(query);
      for (final r in slavArtResults) {
        results.add(HiFiSearchResult(
          id: r.id,
          title: r.title,
          artist: r.artist,
          album: r.album,
          thumbnail: r.thumbnail,
          duration: r.duration,
          source: HiFiSource.fromString(r.source),
          sourceUrl: r.url,
          quality: r.quality ?? 'FLAC',
        ));
      }
    } catch (_) {}

    // Sort by quality (Hi-Res first)
    results.sort((a, b) {
      final aScore = _qualityScore(a.quality);
      final bScore = _qualityScore(b.quality);
      return bScore.compareTo(aScore);
    });

    return results;
  }

  int _qualityScore(String quality) {
    if (quality.contains('24-bit')) return 100;
    if (quality.contains('MQA')) return 90;
    if (quality.contains('FLAC')) return 80;
    if (quality.contains('16-bit')) return 70;
    return 50;
  }

  /// Download a track in FLAC format.
  Future<File?> download(
    HiFiSearchResult result,
    String outputDir, {
    void Function(double progress)? onProgress,
    void Function(String status)? onStatus,
  }) async {
    onStatus
        ?.call('Getting download link from ${result.source.displayName}...');

    // Get download URL from SlavArt
    final downloadUrl = await _slavArt.getDownloadUrl(result.sourceUrl);
    if (downloadUrl == null) {
      onStatus?.call('Failed to get download link');
      return null;
    }

    onStatus?.call('Downloading FLAC...');

    // Download the file
    final file = await _slavArt.downloadFlac(
      downloadUrl,
      outputDir,
      onProgress: onProgress,
    );

    if (file != null) {
      onStatus?.call('Download complete: ${p.basename(file.path)}');
    }

    return file;
  }

  /// Check if a Hi-Fi version is available for a YouTube search result.
  Future<HiFiSearchResult?> findHiFiVersion(String title, String artist) async {
    if (!preferHiFi) {
      return null;
    }

    final query = '$artist $title';
    final results = await search(query);

    if (results.isEmpty) {
      return null;
    }

    // Find best match by title similarity
    for (final r in results) {
      final rTitle = r.title.toLowerCase();
      final searchTitle = title.toLowerCase();
      if (rTitle.contains(searchTitle) || searchTitle.contains(rTitle)) {
        return r;
      }
    }

    // Return first result if no exact match
    return results.first;
  }

  void dispose() {
    _slavArt.dispose();
  }
}

/// Hi-Fi audio source platforms.
enum HiFiSource {
  qobuz,
  tidal,
  deezer,
  unknown;

  static HiFiSource fromString(String s) {
    switch (s.toLowerCase()) {
      case 'qobuz':
        return HiFiSource.qobuz;
      case 'tidal':
        return HiFiSource.tidal;
      case 'deezer':
        return HiFiSource.deezer;
      default:
        return HiFiSource.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case HiFiSource.qobuz:
        return 'Qobuz';
      case HiFiSource.tidal:
        return 'Tidal';
      case HiFiSource.deezer:
        return 'Deezer';
      case HiFiSource.unknown:
        return 'Unknown';
    }
  }

  String get emoji {
    switch (this) {
      case HiFiSource.qobuz:
        return '🟣';
      case HiFiSource.tidal:
        return '🔵';
      case HiFiSource.deezer:
        return '🟢';
      case HiFiSource.unknown:
        return '⚪';
    }
  }
}

/// Search result from Hi-Fi sources.
class HiFiSearchResult {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? thumbnail;
  final int? duration;
  final HiFiSource source;
  final String sourceUrl;
  final String quality;

  HiFiSearchResult({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.thumbnail,
    this.duration,
    required this.source,
    required this.sourceUrl,
    required this.quality,
  });

  /// Quality badge for display.
  String get qualityBadge => '${source.emoji} $quality';

  /// Check if this is Hi-Res quality (24-bit).
  bool get isHiRes => quality.contains('24-bit') || quality.contains('Hi-Res');
}
