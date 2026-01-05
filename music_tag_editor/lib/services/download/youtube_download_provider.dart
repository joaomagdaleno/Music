import 'dart:io';
import 'dart:convert';
import 'package:music_tag_editor/models/download_models.dart';
import 'package:music_tag_editor/models/search_models.dart';
import 'package:music_tag_editor/services/download/download_provider.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:music_tag_editor/services/startup_logger.dart';

typedef ProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
  bool includeParentEnvironment,
  bool runInShell,
  Encoding? stdoutEncoding,
  Encoding? stderrEncoding,
});

class YouTubeDownloadProvider implements DownloadProvider {
  final _deps = DependencyManager.instance;
  final ProcessRunner _processRunner;

  YouTubeDownloadProvider({ProcessRunner? processRunner})
      : _processRunner = processRunner ?? Process.run;

  @override
  bool supports(String url, MediaPlatform platform) => platform == MediaPlatform.youtube ||
        platform == MediaPlatform.youtubeMusic;

  @override
  Future<MediaInfo> getInfo(String url) async {
    final platform = _detectPlatform(url);
    final result = await _processRunner(_deps.ytDlpPath, [
      '--dump-json',
      '--flat-playlist',
      url,
    ]);

    if (result.exitCode != 0) {
      throw Exception('Failed to get YouTube info: ${result.stderr}');
    }

    final json = jsonDecode(result.stdout);
    final formats = <DownloadFormat>[];

    if (json['formats'] != null) {
      for (var f in json['formats']) {
        final formatId = f['format_id'] as String?;
        final ext = f['ext'] as String?;
        final quality = f['format_note'] as String? ?? f['resolution'] as String?;
        final filesize = f['filesize'] as int? ?? f['filesize_approx'] as int?;

        if (formatId == null || ext == null) continue;

        formats.add(DownloadFormat(
          formatId: formatId,
          extension: ext,
          quality: quality ?? 'Unknown',
          isAudioOnly: f['vcodec'] == 'none',
          filesize: filesize,
        ));
      }
    }

    // Add best audio options
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
      url: url,
    );
  }

  @override
  Future<String> download(
    String url,
    DownloadFormat format, {
    void Function(double progress)? onProgress,
  }) async {
    final title = 'download_${DateTime.now().millisecondsSinceEpoch}';
    final outputPath = '${Directory.systemTemp.path}/$title.${format.extension}';

    final args = [
      '-f',
      format.formatId,
      '-o',
      outputPath,
      url,
    ];

    final process = await Process.start(_deps.ytDlpPath, args);

    process.stdout.transform(utf8.decoder).listen((data) {
      // Basic progress parsing logic if needed
      StartupLogger.log('[YouTubeProvider] $data');
    });

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('YouTube download failed with exit code $exitCode');
    }

    return outputPath;
  }

  MediaPlatform _detectPlatform(String url) {
    if (url.contains('music.youtube.com')) {
      return MediaPlatform.youtubeMusic;
    }
    return MediaPlatform.youtube;
  }
}
