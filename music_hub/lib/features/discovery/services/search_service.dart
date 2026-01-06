import 'package:flutter/foundation.dart';
import 'package:music_hub/core/services/database_service.dart';
import 'package:music_hub/core/services/startup_logger.dart';
import 'package:music_hub/features/library/models/download_models.dart';
import 'package:music_hub/features/library/models/search_models.dart';
import 'package:music_hub/features/discovery/services/search/search_provider.dart';
import 'package:music_hub/features/discovery/services/search/youtube_search_provider.dart';
import 'package:music_hub/features/discovery/services/search/slavart_search_provider.dart';

/// Service for searching music across platforms.
/// Refactored to use modular providers and focus exclusively on audio.
class SearchService {
  static SearchService? _instance;
  static SearchService get instance => _instance ??= SearchService._internal();
  static set instance(SearchService value) => _instance = value;
  static void resetInstance() => _instance = null;

  SearchService._internal() {
    _providers = [
      YouTubeSearchProvider(),
      YouTubeMusicSearchProvider(),
      SlavArtSearchProvider(),
    ];
  }

  late List<SearchProvider> _providers;

  @visibleForTesting
  void setProviders(List<SearchProvider> providers) {
    _providers = providers;
  }

  /// Initialize and load settings.
  Future<void> init() async {
    // No initialization needed currently
  }

  /// Search across all platforms with status updates.
  Future<List<SearchResult>> searchAll(
    String query, {
    void Function(MediaPlatform platform, SearchStatus status)? onStatusUpdate,
  }) async {
    final results = <SearchResult>[];

    // Get downloaded tracks for deduplication
    final downloadedTracks = await DatabaseService.instance.getDownloadedUrls();

    // Initial status: all searching
    for (var p in _providers) {
      onStatusUpdate?.call(p.platform, SearchStatus.searching);
    }

    // Run searches in parallel
    final futures = _providers.map((p) => _searchWithStatus(
          p.platform,
          () => p.search(query),
          onStatusUpdate,
        ));

    final lists = await Future.wait(futures);

    // Get all local tracks for metadata matching
    final allLocalTracks = await DatabaseService.instance.getAllTracks();
    final Map<String, String> metadataToPath = {};
    for (var track in allLocalTracks) {
      if (track.localPath != null) {
        final key =
            '${SearchResult.toMatchKey(track.artist)}:${SearchResult.toMatchKey(track.title)}';
        metadataToPath[key] = track.localPath!;
      }
    }

    for (final list in lists) {
      for (var item in list) {
        // 1. URL Deduplication
        if (downloadedTracks.containsKey(item.url)) {
          item.localPath = downloadedTracks[item.url];
        }
        // 2. Metadata Deduplication
        else {
          final itemKey =
              '${SearchResult.toMatchKey(item.artist)}:${SearchResult.toMatchKey(item.title)}';
          if (metadataToPath.containsKey(itemKey)) {
            item.localPath = metadataToPath[itemKey];
          }
        }
        results.add(item);
      }
    }

    // 3. Global Ranking: Prioritize results based on priorityScore and official status
    results.sort((a, b) {
      if (a.priorityScore != null || b.priorityScore != null) {
        return (b.priorityScore ?? 0).compareTo(a.priorityScore ?? 0);
      }
      if (a.isOfficial && !b.isOfficial) return -1;
      if (!a.isOfficial && b.isOfficial) return 1;
      return 0;
    });

    return results;
  }

  Future<List<SearchResult>> _searchWithStatus(
    MediaPlatform platform,
    Future<List<SearchResult>> Function() searchFn,
    void Function(MediaPlatform platform, SearchStatus status)? onStatusUpdate,
  ) async {
    try {
      StartupLogger.log('[SearchService] Executing ${platform.name} search...');
      final results = await searchFn();
      StartupLogger.log(
          '[SearchService] ${platform.name} search finished with ${results.length} results');
      if (results.isEmpty) {
        onStatusUpdate?.call(platform, SearchStatus.noResults);
      } else {
        onStatusUpdate?.call(platform, SearchStatus.completed);
      }
      return results;
    } catch (e, stack) {
      StartupLogger.logError('${platform.name} search FAILED', e, stack);
      onStatusUpdate?.call(platform, SearchStatus.failed);
      return [];
    }
  }

  Future<List<DownloadFormat>> getFormats(
      String url, MediaPlatform platform) async {
    final provider = _providers.firstWhere(
      (p) => p.platform == platform || p.supports(url),
      orElse: () => _providers.first,
    );
    return provider.getFormats(url);
  }

  /// Get direct streaming URL for a given media URL.
  Future<String?> getStreamUrl(
    String url, {
    MediaPlatform? platform,
  }) async {
    // 0. Direct Link Detection
    if (url.startsWith('http') &&
        (url.contains('.slavart-api.') ||
            url.endsWith('.flac') ||
            url.endsWith('.mp3'))) {
      return url;
    }

    final provider = _providers.firstWhere(
      (p) => p.platform == platform || p.supports(url),
      orElse: () => _providers.first,
    );
    return provider.getStreamUrl(url);
  }

  /// Import a playlist from URL.
  Future<List<SearchResult>> importPlaylist(String url) async {
    final provider = _providers.firstWhere(
      (p) => p.supports(url),
      orElse: () => _providers.first,
    );
    return provider.importPlaylist(url);
  }

  /// Backwards compatibility dummy or internal use
  SearchService() : this._internal();
}
