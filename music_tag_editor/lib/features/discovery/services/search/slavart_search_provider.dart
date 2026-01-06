import 'package:music_hub/models/download_models.dart';
import 'package:music_hub/models/search_models.dart';
import 'package:music_hub/services/hifi_download_service.dart';
import 'package:music_hub/features/discovery/services/search/search_provider.dart';

/// Provider for Hi-Fi search (Tidal, Qobuz, Deezer) via SlavArt.
class SlavArtSearchProvider implements SearchProvider {
  @override
  MediaPlatform get platform => MediaPlatform.hifi;

  @override
  Future<List<SearchResult>> search(String query) async {
    try {
      final hifiService = HiFiDownloadService.instance;
      final results = await hifiService.search(query);

      return results
          .map((r) => SearchResult(
                id: r.id,
                title: r.title,
                artist: r.artist,
                album: r.album,
                thumbnail: r.thumbnail,
                duration: r.duration,
                url: r.sourceUrl,
                platform: MediaPlatform.hifi,
                hifiSource: r.source.name, // 'qobuz', 'tidal', 'deezer'
                hifiQuality: r.quality, // e.g. '24-bit/96kHz'
              ))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<DownloadFormat>> getFormats(String url) async => [];

  @override
  Future<String?> getStreamUrl(String url) async {
    // For SlavArt, the search URL is already a direct streamable link or API endpoint.
    if (url.startsWith('http') && url.contains('.slavart-api.')) {
      return url;
    }
    return null;
  }

  @override
  Future<List<SearchResult>> importPlaylist(String url) async => [];

  @override
  bool supports(String url) => url.contains('.slavart-api.');
}
