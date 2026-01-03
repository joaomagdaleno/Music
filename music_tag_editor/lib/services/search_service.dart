import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/hifi_download_service.dart';
import 'package:music_tag_editor/services/startup_logger.dart';
import 'package:path/path.dart' as p;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:spotify/spotify.dart' as spot;

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
  
  spot.SpotifyApi? _spotifyApi;
  bool _spotifyInitAttempted = false;

  /// Expose Spotify API for metadata services.
  Future<spot.SpotifyApi?> get spotifyApi async {
    await _initSpotify();
    return _spotifyApi;
  }

  Future<void> _initSpotify() async {
    if (_spotifyInitAttempted) return;
    _spotifyInitAttempted = true;

    try {
      final creds = await DatabaseService.instance.getSpotifyCredentials();
      if (creds['clientId'] != null && creds['clientSecret'] != null) {
        _spotifyApi = spot.SpotifyApi(spot.SpotifyApiCredentials(
          creds['clientId']!,
          creds['clientSecret']!,
        ));
        StartupLogger.log('[SearchService] Spotify API initialized successfully');
      }
    } catch (e) {
      StartupLogger.log('[SearchService] Failed to initialize Spotify API: $e');
    }
  }

  void resetSpotify() {
    _spotifyApi = null;
    _spotifyInitAttempted = false;
  }

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
    final baseArgs = [
      '--no-check-certificates',
      '--no-cache-dir',
    ];
    if (_ageBypassEnabled && Platform.isWindows) {
      // Try Chrome first, then Edge, then Firefox
      baseArgs.addAll(['--cookies-from-browser', 'chrome']);
    }
    return baseArgs;
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

    // Get all local tracks for metadata matching
    final allLocalTracks = await DatabaseService.instance.getAllTracks();
    final Map<String, String> metadataToPath = {};
    for (var track in allLocalTracks) {
      if (track.localPath != null) {
        final key = '${toMatchKey(track.artist)}:${toMatchKey(track.title)}';
        metadataToPath[key] = track.localPath!;
      }
    }

    for (final list in lists) {
      for (var item in list) {
        // 1. URL Deduplication
        if (downloadedTracks.containsKey(item.url)) {
          item.localPath = downloadedTracks[item.url];
        } 
        // 2. Metadata Deduplication (Fall back if URL didn't match)
        else {
          final itemKey = '${toMatchKey(item.artist)}:${toMatchKey(item.title)}';
          if (metadataToPath.containsKey(itemKey)) {
            item.localPath = metadataToPath[itemKey];
          }
        }
        results.add(item);
      }
    }

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
      StartupLogger.log('[SearchService] ${platform.name} search finished with ${results.length} results');
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

  yt.YoutubeExplode? _ytExplodeOverride;
  final _defaultYtExplode = yt.YoutubeExplode();

  /// Inject a mock YoutubeExplode instance for testing.
  @visibleForTesting
  set ytExplode(yt.YoutubeExplode instance) => _ytExplodeOverride = instance;

  static String cleanMetadata(String s) {
    return s
        .replaceAll(RegExp(r'\(Official.*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[Official.*?\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(Lyrics\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(Audio\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(Video\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(Visualizer\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\[Visualizer\]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\(.*?\)', caseSensitive: false), '') // Remove anything else in parens
        .replaceAll(RegExp(r'\[.*?\]', caseSensitive: false), '') // Remove anything else in brackets
        .replaceAll(RegExp(r' - YouTube$', caseSensitive: false), '')
        .trim();
  }

  static String toMatchKey(String s) {
    return s.toLowerCase().trim();
  }

  SearchResult _parseYouTubeVideo(yt.Video video, MediaPlatform platform) {
    String title = video.title;
    String artist = video.author.replaceAll(' - Topic', '').trim();
    
    // Clean title from common YouTube suffixes before splitting
    title = cleanMetadata(title);

    // Heuristic: If title contains " - ", prioritize it over author unless author is the artist
    if (video.title.contains(' - ')) {
      final parts = video.title.split(' - ');
      if (parts.length >= 2) {
        final potentialArtist = cleanMetadata(parts[0]);
        final potentialTitle = cleanMetadata(parts.sublist(1).join(' - '));
        
        // If author is generic, or if the author is NOT the first part of the title,
        // we assume the uploader is just a fan/channel and the title has the real metadata.
        final genericAuthors = ['7clouds', 'proximity', 'trap nation', 'official music', 'official', 'vevo', 'lyrics', 'audio', 'music', 'videos', 'records', 'entertainment'];
        bool isGeneric = genericAuthors.any((g) => artist.toLowerCase().contains(g)) || video.author.toLowerCase().contains('topic');
        bool authorMatchesTitle = toMatchKey(artist).contains(toMatchKey(potentialArtist)) || toMatchKey(potentialArtist).contains(toMatchKey(artist));

        if (isGeneric || !authorMatchesTitle) {
          artist = potentialArtist;
          title = potentialTitle;
        }
      }
    }

    // Secondary cleanup after potentially splitting
    title = title
        .replaceAll(RegExp(r'ft\..*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'feat\..*$', caseSensitive: false), '')
        .trim();

    return SearchResult(
      id: video.id.value,
      title: title,
      artist: artist,
      thumbnail: video.thumbnails.highResUrl,
      duration: video.duration?.inSeconds,
      url: video.url,
      platform: platform,
    );
  }

  /// Search YouTube using youtube_explode_dart (Native & Fast).
  Future<List<SearchResult>> searchYouTube(String query) async {
    try {
      final results = <SearchResult>[];
      final seenIds = <String>{};
      final seenMeta = <String>{};
      final client = _ytExplodeOverride ?? _defaultYtExplode;
      final searchList = await client.search.search(query);
      
      for (final video in searchList) {
        if (seenIds.contains(video.id.value)) continue;
        
        final res = _parseYouTubeVideo(video, MediaPlatform.youtube);
        final metaKey = '${toMatchKey(res.artist)}:${toMatchKey(res.title)}';
        
        if (seenMeta.contains(metaKey)) continue;
        
        results.add(res);
        seenIds.add(video.id.value);
        seenMeta.add(metaKey);
      }
      return results;
    } catch (e, stack) {
      StartupLogger.logError('YouTube Explode Error', e, stack);
      return [];
    }
  }

  /// Search YouTube Music using youtube_explode_dart (Filtering for music).
  Future<List<SearchResult>> searchYouTubeMusic(String query) async {
    try {
      final results = <SearchResult>[];
      final seenIds = <String>{};
      final seenMeta = <String>{};
      final client = _ytExplodeOverride ?? _defaultYtExplode;
      final searchList = await client.search.search('$query topic');
      
      for (final video in searchList) {
        if (seenIds.contains(video.id.value)) continue;

        final res = _parseYouTubeVideo(video, MediaPlatform.youtubeMusic);
        final metaKey = '${toMatchKey(res.artist)}:${toMatchKey(res.title)}';

        if (seenMeta.contains(metaKey)) continue;

        results.add(res);
        seenIds.add(video.id.value);
        seenMeta.add(metaKey);
      }
      
      // Sort to put topic/official results first if they exist
      results.sort((a, b) {
        final aTopic = a.artist.toLowerCase().contains('topic') || a.title.toLowerCase().contains('official audio');
        final bTopic = b.artist.toLowerCase().contains('topic') || b.title.toLowerCase().contains('official audio');
        if (aTopic && !bTopic) return -1;
        if (!aTopic && bTopic) return 1;
        return 0;
      });

      return results;
    } catch (e, stack) {
      StartupLogger.logError('YT Music Error', e, stack);
      return [];
    }
  }

  Future<List<SearchResult>> searchSpotify(String query) async {
    try {
       final client = _ytExplodeOverride ?? _defaultYtExplode;
       final searchList = await client.search.search('$query official audio');
       final results = <SearchResult>[];
       final seenIds = <String>{};
       final seenMeta = <String>{};

       for (final video in searchList) {
         if (seenIds.contains(video.id.value)) continue;

         final res = _parseYouTubeVideo(video, MediaPlatform.spotify);
         final metaKey = '${toMatchKey(res.artist)}:${toMatchKey(res.title)}';

         if (seenMeta.contains(metaKey)) continue;

         results.add(res);
         seenIds.add(video.id.value);
         seenMeta.add(metaKey);
       }
       return results;
    } catch (e) {
      StartupLogger.log('[SearchService] Authentic Spotify Fallback Error: $e');
      return [];
    }
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
      StartupLogger.log('[SearchService] HiFi search error: $e');
      return [];
    }
  }

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
  Future<String?> getStreamUrl(String url, {
    String? resolution, 
    MediaPlatform? platform,
    bool isVideo = false,
  }) async {
    // 0. Direct Link Detection (Skip extractors for direct files)
    if (url.startsWith('http') && (url.contains('.slavart-api.') || url.endsWith('.flac') || url.endsWith('.mp3'))) {
       StartupLogger.log('[SearchService] Direct link detected: $url');
       return url;
    }

    // 1. Try youtube_explode_dart for YouTube URLs (Fast & Native)
    if (url.contains('youtube.com') || url.contains('youtu.be')) {
      try {
        final client = _ytExplodeOverride ?? _defaultYtExplode;
        final videoId = yt.VideoId.parseVideoId(url);
        if (videoId != null) {
          final manifest = await client.videos.streamsClient.getManifest(videoId);
          
          if (isVideo) {
            // Priority: Muxed streams for video
            if (resolution != null && resolution != 'Auto') {
              final resValue = int.tryParse(resolution.replaceAll('p', '')) ?? 720;
              final stream = manifest.muxed.where((s) => s.videoQuality.index <= resValue).toList();
              if (stream.isNotEmpty) {
                stream.sort((a, b) => b.videoQuality.index.compareTo(a.videoQuality.index));
                StartupLogger.log('[SearchService] Found native video stream URL (YouTube Explode) with resolution $resolution');
                return stream.first.url.toString();
              }
            }
            // Fallback for video: highest muxed
            final stream = manifest.muxed.withHighestBitrate();
            StartupLogger.log('[SearchService] Found highest quality muxed stream URL (YouTube Explode)');
            return stream.url.toString();
          } else {
             // Priority: Audio only for music
             final audioStream = manifest.audioOnly.withHighestBitrate();
             StartupLogger.log('[SearchService] Found native audio-only stream URL (YouTube Explode)');
             return audioStream.url.toString();
          }
        }
      } catch (e) {
        StartupLogger.log('[SearchService] YouTube Explode native extract failed, falling back to yt-dlp: $e');
      }
    }

    // 2. Fallback to yt-dlp (Slower but supports more sites and handles edge cases)
    try {
      final args = [
        ..._getBaseArgs(),
        '-g',
      ];

      if (isVideo) {
        if (resolution != null && resolution != 'Auto') {
          final res = resolution.replaceAll('p', '');
          args.addAll(['-f', 'bestvideo[height<=$res]+bestaudio/best[height<=$res]/best[height<=$res]']);
        } else {
          args.addAll(['-f', 'bestvideo+bestaudio/best']);
        }
      } else {
        // Music only: search for best audio
        args.addAll(['-f', 'bestaudio/best']);
      }
      
      args.add(url);

      debugPrint('[SearchService] getStreamUrl Command: ${_deps.ytDlpPath} ${args.join(' ')}');
      final result = await processRunner(
        _deps.ytDlpPath,
        args,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (result.exitCode == 0) {
        // yt-dlp -g can return multiple lines (video + audio separately). 
        // We only want the first one if we requested a combined format, 
        // but if it returned both, we can only really play one easily in media_kit without complex DASH/HLS merging.
        // Actually, bestvideo+bestaudio/best should return a single URL if it's a direct resource, 
        // or multiple if they are split. MediaKit usually takes a single source.
        final streamUrls = (result.stdout as String).trim().split('\n');
        final streamUrl = streamUrls.first; 
        final displayUrl = streamUrl.length > 50 ? '${streamUrl.substring(0, 50)}...' : streamUrl;
        StartupLogger.log('[SearchService] Found Stream URL (yt-dlp): $displayUrl');
        return streamUrl;
      }
      return null;

    } catch (e, stack) {
      StartupLogger.log('[SearchService] Error extracting stream with yt-dlp: $e\n$stack');
      return null;
    }
  }

  /// Fetches available resolutions for a video.
  Future<List<String>> getAvailableResolutions(String url) async {
    try {
      final details = await getVideoDetails(url);
      if (details == null) return ['Auto'];

      final formats = details['formats'] as List?;
      if (formats == null) return ['Auto'];

      final resolutions = <int>{};
      for (final f in formats) {
        final height = f['height'] as int?;
        if (height != null) resolutions.add(height);
      }

      final sorted = resolutions.toList()..sort((a, b) => b.compareTo(a));
      return ['Auto', ...sorted.map((r) => '${r}p')];
    } catch (e) {
      return ['Auto'];
    }
  }

  /// Fetches detailed video information including available formats and subtitles.
  Future<Map<String, dynamic>?> getVideoDetails(String videoUrl) async {
    final ytDlp = DependencyManager.instance.ytDlpPath;

    try {
      final args = _getBaseArgs();
      args.addAll(['--dump-json', videoUrl]);

      final result = await Process.run(ytDlp, args);

      if (result.exitCode == 0) {
        return jsonDecode(result.stdout as String);
      } else {
        StartupLogger.log('[SearchService] getVideoDetails FAILED. Exit code: ${result.exitCode}');
        StartupLogger.log('[SearchService] stderr: ${result.stderr}');
        return null;
      }
    } catch (e, stack) {
      StartupLogger.log('[SearchService] Error getting video details: $e\n$stack');
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
