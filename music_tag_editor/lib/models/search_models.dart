

/// Status of search on a specific platform.
enum SearchStatus {
  searching,
  completed,
  failed,
  noResults,
}

enum MediaPlatform {
  youtube,
  youtubeMusic,
  hifi,
  local,
  unknown;

  String get displayName {
    switch (this) {
      case MediaPlatform.youtube:
        return 'YouTube';
      case MediaPlatform.youtubeMusic:
        return 'YouTube Music';
      case MediaPlatform.hifi:
        return 'Hi-Fi';
      case MediaPlatform.local:
        return 'Local';
      case MediaPlatform.unknown:
        return 'Unknown';
    }
  }
}

/// Search result from a specific platform.
class SearchResult {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? thumbnail;
  final int? duration;
  final String url;
  final MediaPlatform platform;
  String? localPath;
  final String? genre;
  final String? hifiSource; // 'qobuz', 'tidal', 'deezer' for Hi-Fi results
  final String? hifiQuality; // e.g. '24-bit/96kHz', 'FLAC 16-bit'
  bool isVault;
  bool isDownloaded;

  SearchResult({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.thumbnail,
    this.duration,
    required this.url,
    required this.platform,
    this.localPath,
    this.genre,
    this.hifiSource,
    this.hifiQuality,
    this.isVault = false,
    this.isDownloaded = false,
  });

  String get durationFormatted {
    if (duration == null) {
      return '';
    }
    final minutes = duration! ~/ 60;
    final seconds = (duration! % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'thumbnail': thumbnail,
        'duration': duration,
        'url': url,
        'platform': platform.name,
        'localPath': localPath,
        'genre': genre,
        'hifiSource': hifiSource,
        'hifiQuality': hifiQuality,
        'isVault': isVault ? 1 : 0,
        'isDownloaded': isDownloaded ? 1 : 0,
      };

  factory SearchResult.fromJson(Map<String, dynamic> map) => SearchResult(
      id: map['id'],
      title: map['title'],
      artist: map['artist'],
      album: map['album'],
      thumbnail: map['thumbnail'],
      duration: map['duration'],
      url: map['url'],
      platform: MediaPlatform.values.firstWhere(
        (e) => e.name == map['platform'],
        orElse: () => MediaPlatform.unknown,
      ),
      localPath: map['localPath'],
      genre: map['genre'],
      hifiSource: map['hifiSource'],
      hifiQuality: map['hifiQuality'],
      isVault: (map['isVault'] ?? 0) == 1,
      isDownloaded: (map['isDownloaded'] ?? 0) == 1,
    );

  static String cleanMetadata(String s) => s
      .replaceAll(RegExp(r'\(Official.*?\)', caseSensitive: false), '')
      .replaceAll(RegExp(r'\[Official.*?\]', caseSensitive: false), '')
      .replaceAll(RegExp(r'\(Lyrics\)', caseSensitive: false), '')
      .replaceAll(RegExp(r'\(Audio\)', caseSensitive: false), '')
      .replaceAll(RegExp(r'\(Video\)', caseSensitive: false), '')
      .replaceAll(RegExp(r'\(Visualizer\)', caseSensitive: false), '')
      .replaceAll(RegExp(r'\[Visualizer\]', caseSensitive: false), '')
      .replaceAll(RegExp(r'\(.*?\)', caseSensitive: false),
          '') // Remove anything else in parens
      .replaceAll(RegExp(r'\[.*?\]', caseSensitive: false),
          '') // Remove anything else in brackets
      .replaceAll(RegExp(r' - YouTube$', caseSensitive: false), '')
      .trim();

  static String toMatchKey(String s) => s.toLowerCase().trim();
}
