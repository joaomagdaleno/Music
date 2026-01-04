import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:music_tag_editor/services/startup_logger.dart';
import 'package:music_tag_editor/services/metadata_aggregator_service.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/services/lyrics_service.dart';

/// Platform detected from URL or search.
enum MediaPlatform {
  youtube,
  youtubeMusic,
  spotify,
  hifi, // Tidal, Qobuz, Deezer via SlavArt
  local,
  unknown,
}

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
  final String mediaType; // 'audio' or 'video'

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
    this.mediaType = 'audio',
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
        'platform': platform.toString(),
        'local_path': localPath,
        'is_downloaded': localPath != null ? 1 : 0,
        'genre': genre,
        'hifi_source': hifiSource,
        'hifi_quality': hifiQuality,
        'is_vault': isVault ? 1 : 0,
        'media_type': mediaType,
      };

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    // Handle platform safely
    MediaPlatform platform = MediaPlatform.unknown;
    final platformRaw = json['platform'];
    if (platformRaw is int) {
      if (platformRaw >= 0 && platformRaw < MediaPlatform.values.length) {
        platform = MediaPlatform.values[platformRaw];
      }
    } else if (platformRaw != null) {
      final cleanPlatform =
          platformRaw.toString().split('.').last.toLowerCase();
      platform = MediaPlatform.values.firstWhere(
        (e) => e.name.toLowerCase() == cleanPlatform,
        orElse: () => MediaPlatform.unknown,
      );
    }

    return SearchResult(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Unknown',
      artist: json['artist']?.toString() ?? 'Unknown',
      album: json['album']?.toString(),
      thumbnail: json['thumbnail']?.toString(),
      duration: json['duration'] is int ? json['duration'] : null,
      url: json['url']?.toString() ?? '',
      platform: platform,
      localPath: (json['local_path'] ?? json['localPath'])?.toString(),
      genre: json['genre']?.toString(),
      hifiSource: json['hifi_source']?.toString(),
      hifiQuality: json['hifi_quality']?.toString(),
      isVault: (json['is_vault'] == 1 || json['is_vault'] == true),
      isDownloaded:
          (json['is_downloaded'] == 1 || json['is_downloaded'] == true),
      mediaType: json['media_type']?.toString() ?? 'audio',
    );
  }
}

/// Information about a video/track.
class MediaInfo {
  final String title;
  final String? artist;
  final String? album;
  final String? thumbnail;
  final int? duration;
  final MediaPlatform platform;
  final List<DownloadFormat> formats;

  MediaInfo({
    required this.title,
    this.artist,
    this.album,
    this.thumbnail,
    this.duration,
    required this.platform,
    required this.formats,
  });
}

/// Service for downloading music from various platforms.
class DownloadService {
  static DownloadService? _instance;
  static DownloadService get instance =>
      _instance ??= DownloadService._internal();
  static set instance(DownloadService value) => _instance = value;
  static void resetInstance() => _instance = null;

  DownloadService._internal();

  // For backwards compatibility
  DownloadService() : this._internal();

  final DependencyManager _deps = DependencyManager.instance;

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

  /// For testing: allows mocking process starting
  @visibleForTesting
  Future<Process> Function(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment,
    bool runInShell,
    ProcessStartMode mode,
  }) processStarter = Process.start;

  /// For testing: allows mocking file downloads
  @visibleForTesting
  Future<void> Function(String url, String path) fileDownloader =
      DependencyManager.instance.downloadFile;

  /// Detect platform from URL.
  MediaPlatform detectPlatform(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return MediaPlatform.unknown;
    }

    final host = uri.host.toLowerCase();

    if (host.contains('music.youtube.com')) {
      return MediaPlatform.youtubeMusic;
    } else if (host.contains('youtube.com') || host.contains('youtu.be')) {
      return MediaPlatform.youtube;
    } else if (host.contains('spotify.com') || host.contains('open.spotify')) {
      return MediaPlatform.spotify;
    }

    return MediaPlatform.unknown;
  }

  /// Get media info and available formats.
  Future<MediaInfo> getMediaInfo(String url) async {
    final platform = detectPlatform(url);

    if (platform == MediaPlatform.spotify) {
      return _getSpotifyInfo(url);
    } else {
      return _getYouTubeInfo(url);
    }
  }

  /// Get YouTube/YouTube Music info using yt-dlp.
  Future<MediaInfo> _getYouTubeInfo(String url) async {
    StartupLogger.log('[DownloadService] Getting MediaInfo for YouTube: $url');
    final result = await processRunner(
      _deps.ytDlpPath,
      [
        '--dump-json',
        '--no-download',
        url,
      ],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    if (result.exitCode != 0) {
      StartupLogger.log(
          '[DownloadService] getMediaInfo FAILED: ${result.stderr}');
      throw Exception('Failed to get video info: ${result.stderr}');
    }

    final json = jsonDecode(result.stdout as String);
    final formats = <DownloadFormat>[];

    // Parse available formats
    final formatsList = json['formats'] as List? ?? [];
    for (final f in formatsList) {
      final formatId = f['format_id'] as String? ?? '';
      final ext = f['ext'] as String? ?? '';
      final acodec = f['acodec'] as String? ?? 'none';
      final vcodec = f['vcodec'] as String? ?? 'none';
      final resolution = f['resolution'] as String?;
      final filesize = f['filesize'] as int?;
      final abr = f['abr'] as num?;

      final isAudioOnly = vcodec == 'none' && acodec != 'none';

      if (isAudioOnly) {
        formats.add(DownloadFormat(
          formatId: formatId,
          extension: ext,
          quality: abr != null ? '${abr.toInt()}kbps' : 'audio',
          isAudioOnly: true,
          filesize: filesize,
        ));
      } else if (vcodec != 'none') {
        formats.add(DownloadFormat(
          formatId: formatId,
          extension: ext,
          quality: f['format_note'] as String? ?? '',
          resolution: resolution,
          isAudioOnly: false,
          filesize: filesize,
        ));
      }
    }

    // Add convenient audio-only options
    formats.insert(
        0,
        DownloadFormat(
          formatId: 'bestaudio[ext=m4a]/bestaudio',
          extension: 'm4a',
          quality: 'Best Audio',
          isAudioOnly: true,
        ));
    formats.insert(
        0,
        DownloadFormat(
          formatId: 'bestaudio/best',
          extension: 'mp3',
          quality: 'Best Audio (MP3)',
          isAudioOnly: true,
        ));

    final platform = detectPlatform(url);
    StartupLogger.log(
        '[DownloadService] Successfully parsed info for: ${json['title']}');

    return MediaInfo(
      title: json['title'] as String? ?? 'Unknown',
      artist: json['artist'] as String? ??
          json['uploader'] as String? ??
          json['channel'] as String?,
      album: json['album'] as String?,
      thumbnail: json['thumbnail'] as String?,
      duration: json['duration'] as int?,
      platform: platform,
      formats: formats,
    );
  }

  /// Get Spotify track info (spotdl handles the actual download).
  // spotdl doesn't have a JSON info mode, so we use yt-dlp to search.
  // For now, return basic info.
  Future<MediaInfo> _getSpotifyInfo(String url) async => MediaInfo(
        title: 'Spotify Track',
        artist: null,
        album: null,
        thumbnail: null,
        duration: null,
        platform: MediaPlatform.spotify,
        formats: [
          DownloadFormat(
            formatId: 'mp3',
            extension: 'mp3',
            quality: 'MP3 320kbps',
            isAudioOnly: true,
          ),
          DownloadFormat(
            formatId: 'm4a',
            extension: 'm4a',
            quality: 'M4A AAC',
            isAudioOnly: true,
          ),
          DownloadFormat(
            formatId: 'opus',
            extension: 'opus',
            quality: 'OPUS',
            isAudioOnly: true,
          ),
        ],
      );

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

    if (platform == MediaPlatform.spotify) {
      return _downloadSpotify(url, format, outputDir, onProgress);
    } else {
      return _downloadYouTube(
        url,
        format,
        outputDir,
        onProgress,
        overrideThumbnailUrl: overrideThumbnailUrl,
        title: title,
        artist: artist,
      );
    }
  }

  /// Download from YouTube/YouTube Music using yt-dlp.
  Future<String> _downloadYouTube(
    String url,
    DownloadFormat format,
    String outputDir,
    void Function(double progress, String status)? onProgress, {
    String? overrideThumbnailUrl,
    String? title,
    String? artist,
  }) async {
    final outputTemplate = '$outputDir/%(title)s.%(ext)s';

    final args = <String>[
      '-f',
      format.formatId,
      '--ffmpeg-location',
      _deps.ffmpegPath,
      '-o',
      outputTemplate,
      '--no-playlist',
      '--progress',
      '--embed-metadata', // Basic YouTube metadata as base
      '--embed-subs',
      '--write-auto-subs',
      '--sub-format',
      'srt/best',
    ];

    if (overrideThumbnailUrl == null || overrideThumbnailUrl.isEmpty) {
      args.add('--embed-thumbnail');
    }

    // If downloading as MP3, add conversion
    if (format.extension == 'mp3') {
      args.addAll([
        '-x',
        '--audio-format',
        'mp3',
        '--audio-quality',
        '320k',
        '--convert-thumbnails',
        'jpg',
      ]);
    }

    args.add(url);

    onProgress?.call(0.0, 'Preparando download...');

    final process = await processStarter(
      _deps.ytDlpPath,
      args,
      mode: ProcessStartMode.normal,
    );

    String? outputFile;
    final progressRegex = RegExp(r'\[download\]\s+(\d+\.?\d*)%');

    process.stdout.transform(utf8.decoder).listen((line) {
      final match = progressRegex.firstMatch(line);
      if (match != null) {
        final percent = double.tryParse(match.group(1)!) ?? 0;
        onProgress?.call(
            percent / 100, 'Baixando arquivo: ${percent.toStringAsFixed(1)}%');
      }

      // Capture output filename
      if (line.contains('[download] Destination:')) {
        outputFile = line.split('Destination:').last.trim();
      } else if (line.contains('[download]') &&
          line.contains('has already been downloaded')) {
        // Handle "already downloaded" case to capture filename
        outputFile = line.split('downloaded').last.trim();
        // Sometimes it's just the path
        if (outputFile!.contains(outputDir)) {
          // We have the path
        }
      }
    });

    process.stderr.transform(utf8.decoder).listen((line) {
      // Handle errors
    });

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('Download failed with exit code $exitCode');
    }

    if (outputFile != null) {
      onProgress?.call(0.90, 'Buscando metadados autênticos (MusicBrainz)...');

      String searchTitle;
      String searchArtist;

      // Use efficient passed metadata if available, otherwise fallback to filename parsing
      if (title != null && title.isNotEmpty) {
        searchTitle = title;
        searchArtist = artist ?? '';
      } else {
        // Fallback: Extract from filename
        String baseName = outputFile!.split(Platform.pathSeparator).last;
        baseName = baseName.substring(0, baseName.lastIndexOf('.'));

        searchTitle = SearchService.cleanMetadata(baseName);
        searchArtist = '';

        if (searchTitle.contains(' - ')) {
          final parts = searchTitle.split(' - ');
          if (parts.length >= 2) {
            searchArtist = parts[0].trim();
            searchTitle = parts.sublist(1).join(' - ').trim();
          }
        }
      }

      // 2. Fetch High-Quality Metadata
      final aggregator = MetadataAggregatorService.instance;
      // We pass the clean title/artist to the aggregator
      final metadata =
          await aggregator.aggregateMetadata(searchTitle, searchArtist);

      // 3. Fetch lyrics online
      final lyrics = await LyricsService.instance
          .fetchRawLyrics(searchTitle, searchArtist);

      onProgress?.call(0.95, 'Embutindo metadados e capa...');

      // Embed the enhanced metadata using FFmpeg
      await _embedMetadata(outputFile!, metadata, lyrics: lyrics);
    }

    onProgress?.call(1.0, 'Download concluído!');
    return outputFile ?? outputDir;
  }

  Future<void> _embedMetadata(
    String audioPath,
    AggregatedMetadata metadata, {
    String? lyrics,
  }) async {
    try {
      final tempOut = '${audioPath}_temp.mp3';

      final args = <String>[
        '-y',
        '-i',
        audioPath,
      ];

      // Handle Cover Art
      File? imageFile;
      if (metadata.thumbnail != null && metadata.thumbnail!.isNotEmpty) {
        imageFile = File('${audioPath}_thumb.jpg');
        await fileDownloader(metadata.thumbnail!, imageFile.path);
        args.addAll(['-i', imageFile.path]);
        args.addAll(['-map', '0:0', '-map', '1:0']);
      } else {
        args.addAll(['-map', '0:0']);
      }

      args.addAll(['-c', 'copy', '-id3v2_version', '3']);

      // Add Metadata Tags
      if (metadata.title != null)
        args.addAll(['-metadata', 'title=${metadata.title}']);
      if (metadata.artist != null)
        args.addAll(['-metadata', 'artist=${metadata.artist}']);
      if (metadata.album != null)
        args.addAll(['-metadata', 'album=${metadata.album}']);
      if (metadata.genre != null)
        args.addAll(['-metadata', 'genre=${metadata.genre}']);
      if (metadata.year != null)
        args.addAll(['-metadata', 'date=${metadata.year}']);
      if (lyrics != null) {
        args.addAll(['-metadata', 'lyrics=$lyrics']);
        args.addAll(['-metadata', 'USLT=$lyrics']);
      }

      args.add(tempOut);

      final result = await processRunner(_deps.ffmpegPath, args);

      if (result.exitCode == 0) {
        if (await File(audioPath).exists()) {
          await File(audioPath).delete();
        }
        await File(tempOut).rename(audioPath);
      } else {
        StartupLogger.log('FFmpeg metadata embed failed: ${result.stderr}');
      }

      if (imageFile != null && await imageFile.exists()) {
        await imageFile.delete();
      }
    } catch (e) {
      StartupLogger.log('Error embedding metadata: $e');
    }
  }

  /// Download from Spotify using spotdl.
  Future<String> _downloadSpotify(
    String url,
    DownloadFormat format,
    String outputDir,
    void Function(double progress, String status)? onProgress,
  ) async {
    onProgress?.call(0.0, 'Iniciando download do Spotify...');

    final result = await processRunner(
      _deps.spotdlPath,
      [
        'download',
        url,
        '--output',
        outputDir,
        '--format',
        format.extension,
        '--bitrate',
        '320k',
        '--ffmpeg',
        _deps.ffmpegPath,
      ],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );

    if (result.exitCode != 0) {
      throw Exception('Spotify download failed: ${result.stderr}');
    }

    onProgress?.call(1.0, 'Complete!');
    return outputDir;
  }
}
