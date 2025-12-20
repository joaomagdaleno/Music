import 'dart:io';
import 'dart:convert';
import 'dependency_manager.dart';

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
  final String platform;
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

/// Platform detected from URL.
enum MediaPlatform {
  youtube,
  youtubeMusic,
  spotify,
  unknown,
}

/// Service for downloading music from various platforms.
class DownloadService {
  final DependencyManager _deps = DependencyManager.instance;

  /// Detect platform from URL.
  MediaPlatform detectPlatform(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return MediaPlatform.unknown;

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
    final result = await Process.run(
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

    return MediaInfo(
      title: json['title'] as String? ?? 'Unknown',
      artist: json['artist'] as String? ??
          json['uploader'] as String? ??
          json['channel'] as String?,
      album: json['album'] as String?,
      thumbnail: json['thumbnail'] as String?,
      duration: json['duration'] as int?,
      platform:
          platform == MediaPlatform.youtubeMusic ? 'YouTube Music' : 'YouTube',
      formats: formats,
    );
  }

  /// Get Spotify track info (spotdl handles the actual download).
  Future<MediaInfo> _getSpotifyInfo(String url) async {
    // spotdl doesn't have a JSON info mode, so we use yt-dlp to search
    // For now, return basic info
    return MediaInfo(
      title: 'Spotify Track',
      artist: null,
      album: null,
      thumbnail: null,
      duration: null,
      platform: 'Spotify',
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
  }

  /// Download media with selected format.
  Future<String> download(
    String url,
    DownloadFormat format,
    String outputDir, {
    void Function(double progress, String status)? onProgress,
  }) async {
    final platform = detectPlatform(url);

    if (platform == MediaPlatform.spotify) {
      return _downloadSpotify(url, format, outputDir, onProgress);
    } else {
      return _downloadYouTube(url, format, outputDir, onProgress);
    }
  }

  /// Download from YouTube/YouTube Music using yt-dlp.
  Future<String> _downloadYouTube(
    String url,
    DownloadFormat format,
    String outputDir,
    void Function(double progress, String status)? onProgress,
  ) async {
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
    ];

    // If downloading as MP3, add conversion
    if (format.extension == 'mp3') {
      args.addAll([
        '-x',
        '--audio-format',
        'mp3',
        '--audio-quality',
        '0',
      ]);
    }

    args.add(url);

    onProgress?.call(0.0, 'Starting download...');

    final process = await Process.start(
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
            percent / 100, 'Downloading: ${percent.toStringAsFixed(1)}%');
      }

      // Capture output filename
      if (line.contains('[download] Destination:')) {
        outputFile = line.split('Destination:').last.trim();
      }
    });

    process.stderr.transform(utf8.decoder).listen((line) {
      // Handle errors
    });

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('Download failed with exit code $exitCode');
    }

    onProgress?.call(1.0, 'Complete!');
    return outputFile ?? outputDir;
  }

  /// Download from Spotify using spotdl.
  Future<String> _downloadSpotify(
    String url,
    DownloadFormat format,
    String outputDir,
    void Function(double progress, String status)? onProgress,
  ) async {
    onProgress?.call(0.0, 'Starting Spotify download...');

    final result = await Process.run(
      _deps.spotdlPath,
      [
        'download',
        url,
        '--output',
        outputDir,
        '--format',
        format.extension,
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
