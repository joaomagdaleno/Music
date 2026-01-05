import 'package:music_tag_editor/models/search_models.dart';

/// Available audio/video format for download.
class DownloadFormat {
  final String formatId;
  final String extension;
  final String quality;
  final String? resolution;
  final int? filesize;
  final bool isAudioOnly;

  DownloadFormat({
    required this.formatId,
    required this.extension,
    required this.quality,
    this.resolution,
    this.filesize,
    required this.isAudioOnly,
  });

  String get displayName {
    if (isAudioOnly) {
      return '$extension - $quality';
    } else {
      return '$extension - ${resolution ?? quality}';
    }
  }

  @override
  String toString() => displayName;
}

/// Information about a video/track.
class MediaInfo {
  final String title;
  final String? artist;
  final String? album;
  final String? thumbnail;
  final int? duration;
  final List<DownloadFormat> formats;
  final String url;
  final MediaPlatform platform;

  MediaInfo({
    required this.title,
    this.artist,
    this.album,
    this.thumbnail,
    this.duration,
    required this.formats,
    required this.url,
    required this.platform,
  });

  String? get thumbnailUrl => thumbnail;
}
