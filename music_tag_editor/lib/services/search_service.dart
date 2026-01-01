import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'dart:convert';
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/hifi_download_service.dart';
import 'package:path/path.dart' as p;

/// Status of search on a specific platform.
enum SearchStatus {
  searching,
  completed,
  failed,
  noResults,
}

/// Service for searching music across platforms.
class SearchService {
  static SearchService? _instance;
  static SearchService get instance => _instance ??= SearchService._internal();
  static set instance(SearchService value) => _instance = value;
  static void resetInstance() => _instance = null;

  SearchService._internal();

  // For backwards compatibility and internal use
  SearchService() : this._internal();
  final DependencyManager _deps = DependencyManager.instance;
  bool _ageBypassEnabled = false;

  /// For testing: allows mocking process execution
  @visibleForTesting
  Future<ProcessResult> Function(
    String executable,
    List<String> arguments, {
    Map<String, String>? environment,
    bool includeParentEnvironment,
    bool runInShell,
    Encoding? stdoutEncoding,
    Encoding? stderrEncoding,
  }) processRunner = Process.run;

  /// Initialize and load settings.
  Future<void> init() async {
    _ageBypassEnabled = await DatabaseService.instance.loadAgeBypass();
  }

  /// Update age bypass setting.
  void setAgeBypass(bool enabled) {
    _ageBypassEnabled = enabled;
  }

  /// Get base yt-dlp args (with cookies if age bypass enabled).
  List<String> _getBaseArgs() {
    if (_ageBypassEnabled && Platform.isWindows) {
      // Try Chrome first, then Edge, then Firefox
      return ['--cookies-from-browser', 'chrome'];
    }
    return [];
  }

  /// Search across all platforms with status updates.
  Future<List<SearchResult>> searchAll(
    String query, {
    void Function(MediaPlatform platform, SearchStatus status)? onStatusUpdate,
  }) async {
    final results = <SearchResult>[];

    // Initial status: all searching
    onStatusUpdate?.call(MediaPlatform.youtube, SearchStatus.searching);
    onStatusUpdate?.call(MediaPlatform.youtubeMusic, SearchStatus.searching);
    onStatusUpdate?.call(MediaPlatform.spotify, SearchStatus.searching);
    onStatusUpdate?.call(MediaPlatform.hifi, SearchStatus.searching);

    // Run searches in parallel
    final futures = [
      _searchWithStatus(
          MediaPlatform.youtube, () => searchYouTube(query), onStatusUpdate),
      _searchWithStatus(MediaPlatform.youtubeMusic,
          () => searchYouTubeMusic(query), onStatusUpdate),
      _searchWithStatus(
          MediaPlatform.spotify, () => searchSpotify(query), onStatusUpdate),
      _searchWithStatus(
          MediaPlatform.hifi, () => searchHiFi(query), onStatusUpdate),
    ];

    final lists = await Future.wait(futures);

    for (final list in lists) {
      results.addAll(list);
    }

    return results;
  }

  Future<List<SearchResult>> _searchWithStatus(
    MediaPlatform platform,
    Future<List<SearchResult>> Function() searchFn,
    void Function(MediaPlatform platform, SearchStatus status)? onStatusUpdate,
  ) async {
    try {
      debugPrint('[SearchService] Executing ${platform.name} search...');
      final results = await searchFn();
      debugPrint('[SearchService] ${platform.name} search finished with ${results.length} results');
      if (results.isEmpty) {
        onStatusUpdate?.call(platform, SearchStatus.noResults);
      } else {
        onStatusUpdate?.call(platform, SearchStatus.completed);
      }
      return results;
    } catch (e, stack) {
      debugPrint('[SearchService] ${platform.name} search FAILED: $e\n$stack');
      onStatusUpdate?.call(platform, SearchStatus.failed);
      return [];
    }
  }

  /// Search YouTube using yt-dlp.
  Future<List<SearchResult>> searchYouTube(String query) async {
    try {
      final args = [
        ..._getBaseArgs(),
        '--quiet',
        '--no-warnings',
        'ytsearch10:$query',
        '--dump-json',
        '--flat-playlist',
        '--no-download',
      ];

      final result = await processRunner(
        _deps.ytDlpPath,
        args,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (result.exitCode != 0) {
        return [];
      }

      final results = <SearchResult>[];
      final lines = (result.stdout as String).split('\n');

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final json = jsonDecode(line);
          
          // Improved artist extraction
          String artist = json['artist'] as String? ??
              json['creator'] as String? ??
              json['uploader'] as String? ??
              json['channel'] as String? ??
              json['uploader_id'] as String? ??
              'Unknown';
          
          if (artist.endsWith(' - Topic')) {
            artist = artist.replaceAll(' - Topic', '');
          }

          // Pick better thumbnail
          String? thumbnail = json['thumbnail'] as String?;
          if (json['thumbnails'] != null && (json['thumbnails'] as List).isNotEmpty) {
             // Pick the one with highest resolution or last one
             thumbnail = (json['thumbnails'] as List).last['url'] as String?;
          }

          results.add(SearchResult(
            id: json['id'] as String? ?? '',
            title: json['title'] as String? ?? 'Unknown',
            artist: artist,
            thumbnail: thumbnail,
            duration: json['duration'] as int?,
            url: 'https://www.youtube.com/watch?v=${json['id']}',
            platform: MediaPlatform.youtube,
          ));
        } catch (_) {}
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  /// Search YouTube Music using yt-dlp.
  Future<List<SearchResult>> searchYouTubeMusic(String query) async {
    try {
      final args = [
        ..._getBaseArgs(),
        '--quiet',
        '--no-warnings',
        'https://music.youtube.com/search?q=${Uri.encodeComponent(query)}',
        '--dump-json',
        '--flat-playlist',
        '--no-download',
        '-I', '1:5', // First 5 results
      ];

      final result = await processRunner(
        _deps.ytDlpPath,
        args,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (result.exitCode != 0) {
        return [];
      }

      final results = <SearchResult>[];
      final lines = (result.stdout as String).split('\n');

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final json = jsonDecode(line);
          String artist = json['artist'] as String? ??
              json['creator'] as String? ??
              json['uploader'] as String? ??
              json['channel'] as String? ??
              'Unknown';
          
          if (artist.endsWith(' - Topic')) {
            artist = artist.replaceAll(' - Topic', '');
          }

          String? thumbnail = json['thumbnail'] as String?;
          if (json['thumbnails'] != null && (json['thumbnails'] as List).isNotEmpty) {
             thumbnail = (json['thumbnails'] as List).last['url'] as String?;
          }

          results.add(SearchResult(
            id: json['id'] as String? ?? '',
            title: json['title'] as String? ?? 'Unknown',
            artist: artist,
            album: json['album'] as String?,
            thumbnail: thumbnail,
            duration: json['duration'] as int?,
            url: 'https://music.youtube.com/watch?v=${json['id']}',
            platform: MediaPlatform.youtubeMusic,
          ));
        } catch (_) {}
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  /// Search Spotify using a hybrid approach (YouTube search with Spotify metadata lookup).
  Future<List<SearchResult>> searchSpotify(String query) async {
    // 1. Search YouTube for "query spotify" to get relevant audio tracks
    final ytResults = await searchYouTube('$query official audio');
    
    // 2. Map results to Spotify platform and try to enrich with real metadata if possible
    // (In a real app, we'd use Spotify Web API here, but this hybrid works for streaming)
    return ytResults.map((r) => SearchResult(
      id: r.id,
      title: r.title.replaceAll(RegExp(r'\(Audio\)|\(Official Video\)|\(Lyrics\)', caseSensitive: false), '').trim(),
      artist: r.artist,
      thumbnail: r.thumbnail,
      duration: r.duration,
      url: r.url,
      platform: MediaPlatform.spotify,
    )).toList();
  }

  /// Search Hi-Fi platforms (Tidal, Qobuz, Deezer) via SlavArt.
  Future<List<SearchResult>> searchHiFi(String query) async {
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

  /// Get available formats for a URL.
  Future<List<DownloadFormat>> getFormats(
      String url, MediaPlatform platform) async {
    if (platform == MediaPlatform.spotify) {
      return [
        DownloadFormat(
            formatId: 'mp3',
            quality: '320kbps',
            extension: 'mp3',
            isAudioOnly: true),
        DownloadFormat(
            formatId: 'm4a',
            quality: 'AAC',
            extension: 'm4a',
            isAudioOnly: true),
        DownloadFormat(
            formatId: 'opus',
            quality: 'Best',
            extension: 'opus',
            isAudioOnly: true),
      ];
    }

    try {
      final result = await processRunner(
        _deps.ytDlpPath,
        ['--dump-json', '--no-download', url],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (result.exitCode != 0) {
        return _defaultFormats();
      }

      final json = jsonDecode(result.stdout as String);
      final formats = <DownloadFormat>[];

      // Add convenient audio options first
      formats.add(DownloadFormat(
          formatId: 'bestaudio/best',
          quality: 'Best Audio (MP3)',
          extension: 'mp3',
          isAudioOnly: true));
      formats.add(DownloadFormat(
          formatId: 'bestaudio[ext=m4a]/bestaudio',
          quality: 'Best Audio (M4A)',
          extension: 'm4a',
          isAudioOnly: true));

      // Parse available formats
      final formatsList = json['formats'] as List? ?? [];
      for (final f in formatsList) {
        final formatId = f['format_id'] as String? ?? '';
        final ext = f['ext'] as String? ?? '';
        final vcodec = f['vcodec'] as String? ?? 'none';
        final acodec = f['acodec'] as String? ?? 'none';
        final resolution = f['resolution'] as String?;
        final abr = f['abr'] as num?;

        final isAudioOnly = vcodec == 'none' && acodec != 'none';

        if (isAudioOnly && abr != null) {
          formats.add(DownloadFormat(
            formatId: formatId,
            quality: '${abr.toInt()}kbps',
            extension: ext,
            isAudioOnly: true,
          ));
        } else if (vcodec != 'none' && resolution != null) {
          formats.add(DownloadFormat(
            formatId: formatId,
            quality: resolution,
            extension: ext,
            isAudioOnly: false,
          ));
        }
      }

      return formats;
    } catch (e) {
      return _defaultFormats();
    }
  }

  List<DownloadFormat> _defaultFormats() {
    return [
      DownloadFormat(
          formatId: 'bestaudio/best',
          quality: 'Best Audio (MP3)',
          extension: 'mp3',
          isAudioOnly: true),
      DownloadFormat(
          formatId: 'bestaudio[ext=m4a]/bestaudio',
          quality: 'Best Audio (M4A)',
          extension: 'm4a',
          isAudioOnly: true),
    ];
  }

  /// Get direct streaming URL for a given media URL.
  Future<String?> getStreamUrl(String url) async {
    try {
      final args = [
        ..._getBaseArgs(),
        '-g',
        '-f',
        'bestaudio/best',
        url,
      ];

      debugPrint('[SearchService] getStreamUrl Command: ${_deps.ytDlpPath} ${args.join(' ')}');
      final result = await processRunner(
        _deps.ytDlpPath,
        args,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (result.exitCode == 0) {
        final streamUrl = (result.stdout as String).trim();
        debugPrint('[SearchService] Found Stream URL: ${streamUrl.substring(0, 50)}...');
        return streamUrl;
      }
      debugPrint('[SearchService] getStreamUrl FAILED: ${result.stderr}');
      return null;
    } catch (e, stack) {
      debugPrint('[SearchService] Error extracting stream: $e\n$stack');
      return null;
    }
  }

  /// Search for a matching track on Spotify to get high-quality metadata/thumbnail.
  Future<SearchResult?> findSpotifyMatch(SearchResult ytResult) async {
    try {
      final query = '${ytResult.artist} ${ytResult.title}';
      final results = await searchSpotify(query);

      if (results.isEmpty) {
        return null;
      }

      // Basic similarity check (can be improved)
      final ytTitle = ytResult.title.toLowerCase();
      final match = results.firstWhere(
        (s) {
          final sTitle = s.title.toLowerCase();
          return sTitle.contains(ytTitle) || ytTitle.contains(sTitle);
        },
        orElse: () => results.first,
      );

      return match;
    } catch (e) {
      return null;
    }
  }

  /// Import a playlist from YouTube or Spotify URL.
  Future<List<SearchResult>> importPlaylist(String url) async {
    if (url.contains('spotify.com')) {
      return _importSpotifyPlaylist(url);
    } else {
      return _importYouTubePlaylist(url);
    }
  }

  Future<List<SearchResult>> _importYouTubePlaylist(String url) async {
    try {
      final result = await processRunner(
        _deps.ytDlpPath,
        [
          '--dump-json',
          '--flat-playlist',
          '--no-download',
          url,
        ],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (result.exitCode != 0) {
        return [];
      }

      final results = <SearchResult>[];
      final lines = (result.stdout as String).split('\n');

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final json = jsonDecode(line);
          results.add(SearchResult(
            id: json['id'] as String? ?? '',
            title: json['title'] as String? ?? 'Unknown',
            artist: json['uploader'] as String? ??
                json['channel'] as String? ??
                'Unknown',
            thumbnail: json['thumbnail'] as String?,
            duration: (json['duration'] as num?)?.toInt(),
            url: 'https://www.youtube.com/watch?v=${json['id']}',
            platform: MediaPlatform.youtube,
          ));
        } catch (_) {}
      }
      return results;
    } catch (e) {
      return [];
    }
  }

  Future<List<SearchResult>> _importSpotifyPlaylist(String url) async {
    final tempFile = File(p.join(Directory.systemTemp.path,
        'temp_${DateTime.now().millisecondsSinceEpoch}.spotdl'));
    try {
      final result = await processRunner(
        _deps.spotdlPath,
        [
          'save',
          url,
          '--save-file',
          tempFile.path,
        ],
      );

      if (result.exitCode != 0) {
        return [];
      }

      final exists = await tempFile.exists();
      if (!exists) {
        return [];
      }

      final content = await tempFile.readAsString();
      final List<SearchResult> results = [];
      final lines = content.split('\n');

      for (var line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final json = jsonDecode(line);
          results.add(SearchResult(
            id: json['url'] ?? '',
            title: json['name'] ?? 'Unknown',
            artist: json['artists']?[0] ?? 'Unknown',
            album: json['album'],
            thumbnail: json['cover_url'],
            duration: (json['duration'] as num?)?.toInt(),
            url: json['url'] ?? '',
            platform: MediaPlatform.spotify,
          ));
        } catch (_) {}
      }
      return results;
    } catch (e) {
      return [];
    } finally {
      if (await tempFile.exists()) await tempFile.delete();
    }
  }
}
