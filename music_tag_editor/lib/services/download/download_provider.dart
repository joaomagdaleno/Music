import 'package:music_tag_editor/models/download_models.dart';
import 'package:music_tag_editor/models/search_models.dart';

/// Base interface for platform-specific download providers.
abstract class DownloadProvider {
  /// Check if this provider supports the given URL and platform.
  bool supports(String url, MediaPlatform platform);

  /// Get media information for the given URL.
  Future<MediaInfo> getInfo(String url);

  /// Download the media from the given URL.
  /// Returns the path to the downloaded file.
  Future<String> download(
    String url,
    DownloadFormat format, {
    void Function(double progress)? onProgress,
  });
}
