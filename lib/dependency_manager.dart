import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'dart:convert';
import 'package:archive/archive.dart';

/// Manages external CLI tools (yt-dlp, spotdl, FFmpeg).
/// Auto-downloads on first run, no user intervention needed.
class DependencyManager {
  static DependencyManager? _instance;
  static DependencyManager get instance => _instance ??= DependencyManager._();
  DependencyManager._();

  late String _binDir;
  bool _initialized = false;

  /// URLs for downloading tools
  static const _ytDlpReleaseApi =
      'https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest';
  static const _spotdlReleaseApi =
      'https://api.github.com/repos/spotDL/spotify-downloader/releases/latest';
  static const _ffmpegUrl =
      'https://github.com/yt-dlp/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip';

  /// Initialize the dependency manager and ensure tools are installed.
  Future<void> ensureDependencies({
    void Function(String status, double progress)? onProgress,
  }) async {
    if (_initialized) return;

    _binDir = await _getBinDirectory();
    await Directory(_binDir).create(recursive: true);

    // Check and download each tool
    final tools = [
      ('yt-dlp', _getYtDlpPath(), _downloadYtDlp),
      ('spotdl', _getSpotdlPath(), _downloadSpotdl),
      ('ffmpeg', _getFFmpegPath(), _downloadFFmpeg),
    ];

    for (var i = 0; i < tools.length; i++) {
      final (name, path, downloader) = tools[i];
      if (!await File(path).exists()) {
        onProgress?.call('Downloading $name...', (i / tools.length));
        await downloader();
      }
    }

    onProgress?.call('Ready!', 1.0);
    _initialized = true;
  }

  /// Get the binary directory for storing tools.
  Future<String> _getBinDirectory() async {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA']!;
      return p.join(appData, 'music_tag_editor', 'bin');
    } else if (Platform.isLinux || Platform.isMacOS) {
      final home = Platform.environment['HOME']!;
      return p.join(home, '.local', 'share', 'music_tag_editor', 'bin');
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Get path to yt-dlp executable.
  String _getYtDlpPath() {
    final ext = Platform.isWindows ? '.exe' : '';
    return p.join(_binDir, 'yt-dlp$ext');
  }

  /// Get path to spotdl executable.
  String _getSpotdlPath() {
    final ext = Platform.isWindows ? '.exe' : '';
    return p.join(_binDir, 'spotdl$ext');
  }

  /// Get path to FFmpeg executable.
  String _getFFmpegPath() {
    final ext = Platform.isWindows ? '.exe' : '';
    return p.join(_binDir, 'ffmpeg$ext');
  }

  /// Public getters for tool paths.
  String get ytDlpPath => _getYtDlpPath();
  String get spotdlPath => _getSpotdlPath();
  String get ffmpegPath => _getFFmpegPath();

  /// Download yt-dlp from GitHub releases.
  Future<void> _downloadYtDlp() async {
    final response = await http.get(Uri.parse(_ytDlpReleaseApi));
    final json = jsonDecode(response.body);
    final assets = json['assets'] as List;

    String assetName;
    if (Platform.isWindows) {
      assetName = 'yt-dlp.exe';
    } else if (Platform.isLinux) {
      assetName = 'yt-dlp_linux';
    } else if (Platform.isMacOS) {
      assetName = 'yt-dlp_macos';
    } else {
      throw UnsupportedError('Unsupported platform');
    }

    final asset = assets.firstWhere((a) => a['name'] == assetName);
    final downloadUrl = asset['browser_download_url'] as String;

    await _downloadFile(downloadUrl, _getYtDlpPath());
    await _makeExecutable(_getYtDlpPath());
  }

  /// Download spotdl from GitHub releases.
  Future<void> _downloadSpotdl() async {
    final response = await http.get(Uri.parse(_spotdlReleaseApi));
    final json = jsonDecode(response.body);
    final assets = json['assets'] as List;

    String assetName;
    if (Platform.isWindows) {
      assetName = 'spotdl-win32-x64.exe';
    } else if (Platform.isLinux) {
      assetName = 'spotdl-linux-x64';
    } else if (Platform.isMacOS) {
      assetName = 'spotdl-darwin-x64';
    } else {
      throw UnsupportedError('Unsupported platform');
    }

    // Find asset that matches (may have version in name)
    final asset = assets.firstWhere(
      (a) => (a['name'] as String).contains(
        assetName.replaceAll('.exe', '').replaceAll('spotdl-', ''),
      ),
      orElse: () => null,
    );

    if (asset == null) {
      // Fallback: try to find any Windows/Linux/macOS asset
      final platform = Platform.isWindows
          ? 'win'
          : Platform.isLinux
              ? 'linux'
              : 'darwin';
      final fallbackAsset = assets.firstWhere(
        (a) =>
            (a['name'] as String).contains(platform) &&
            !(a['name'] as String).contains('.sha256'),
      );
      final downloadUrl = fallbackAsset['browser_download_url'] as String;
      await _downloadFile(downloadUrl, _getSpotdlPath());
    } else {
      final downloadUrl = asset['browser_download_url'] as String;
      await _downloadFile(downloadUrl, _getSpotdlPath());
    }

    await _makeExecutable(_getSpotdlPath());
  }

  /// Download FFmpeg from yt-dlp's FFmpeg builds.
  Future<void> _downloadFFmpeg() async {
    if (Platform.isWindows) {
      final zipPath = p.join(_binDir, 'ffmpeg.zip');
      await _downloadFile(_ffmpegUrl, zipPath);

      // Extract zip
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        if (file.name.endsWith('ffmpeg.exe')) {
          final outputPath = _getFFmpegPath();
          await File(outputPath).writeAsBytes(file.content as List<int>);
          break;
        }
      }

      await File(zipPath).delete();
    } else {
      // Linux/macOS: use system ffmpeg or download static build
      final result = await Process.run('which', ['ffmpeg']);
      if (result.exitCode == 0) {
        // ffmpeg already in PATH, create symlink
        final systemPath = (result.stdout as String).trim();
        await Link(_getFFmpegPath()).create(systemPath);
      } else {
        // Download static build for Linux
        const linuxUrl =
            'https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz';
        throw UnimplementedError(
          'FFmpeg auto-install for Linux not yet implemented. '
          'Please install ffmpeg: sudo apt install ffmpeg',
        );
      }
    }
  }

  /// Download a file from URL to local path.
  Future<void> _downloadFile(String url, String path) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw HttpException('Failed to download: $url');
    }
    await File(path).writeAsBytes(response.bodyBytes);
  }

  /// Make file executable (Linux/macOS).
  Future<void> _makeExecutable(String path) async {
    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', path]);
    }
  }

  /// Check if all dependencies are installed.
  Future<bool> areAllDependenciesInstalled() async {
    _binDir = await _getBinDirectory();
    return await File(_getYtDlpPath()).exists() &&
        await File(_getSpotdlPath()).exists() &&
        await File(_getFFmpegPath()).exists();
  }
}
