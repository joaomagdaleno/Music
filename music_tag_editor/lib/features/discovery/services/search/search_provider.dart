import 'package:music_hub/models/download_models.dart';
import 'package:music_hub/models/search_models.dart';

/// Contract for music search providers.
abstract class SearchProvider {
  /// Unique identifier for this provider.
  MediaPlatform get platform;

  /// Search for tracks on this platform.
  Future<List<SearchResult>> search(String query);

  /// Get available download formats for a specific URL.
  Future<List<DownloadFormat>> getFormats(String url);

  /// Get direct streaming URL for audio.
  Future<String?> getStreamUrl(String url);

  /// Import a playlist from a URL.
  Future<List<SearchResult>> importPlaylist(String url);

  /// Whether this provider supports the given URL.
  bool supports(String url);
}
