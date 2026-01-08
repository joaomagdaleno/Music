import 'package:music_hub/features/library/models/search_models.dart';
import 'package:music_hub/features/player/services/playback_service.dart';
import 'package:music_hub/core/services/startup_logger.dart';
import 'package:music_hub/features/discovery/services/youtube_streamer_service.dart';
import 'package:music_hub/features/discovery/services/offline_download_service.dart';
import 'package:music_hub/core/services/database_service.dart'; // For saving download status

import 'package:rxdart/rxdart.dart';

class DownloadProgress {
  final String id;
  final double progress;
  final String status;
  final bool isCompleted;
  final bool isFailed;

  DownloadProgress({
    required this.id,
    required this.progress,
    required this.status,
    this.isCompleted = false,
    this.isFailed = false,
  });
}

/// Orchestrates the separated Stream (Instant Play) and Background Download experiences.
class MusicManagerService {
  static MusicManagerService? _instance;
  static MusicManagerService get instance =>
      _instance ??= MusicManagerService._internal();

  MusicManagerService._internal();

  // New Services
  final YouTubeStreamerService _streamer = YouTubeStreamerService();
  final OfflineDownloadService _downloader = OfflineDownloadService();

  final Set<String> _downloadingIds = {};

  final _progressController =
      BehaviorSubject<Map<String, DownloadProgress>>.seeded({});
  Stream<Map<String, DownloadProgress>> get progressStream =>
      _progressController.stream;

  /// Plays the track instantly via streaming using YouTubeStreamerService for best quality.
  Future<void> playInstant(SearchResult result) async {
    StartupLogger.log(
        '[MusicManager] Instant play requested for: ${result.title}');

    // 1. Try to find a high quality stream
    final streamUrl =
        await _streamer.getStreamUrl('${result.artist} - ${result.title}');

    if (streamUrl != null) {
      StartupLogger.log('[MusicManager] Playing via High Quality Stream');
      await PlaybackService.instance.playStream(streamUrl, result);
    } else {
      StartupLogger.log(
          '[MusicManager] Streamer failed, falling back to standard playback');
      await PlaybackService.instance.playSearchResult(result);
    }
  }

  /// Downloads the track in the background using OfflineDownloadService.
  Future<void> downloadTrack(SearchResult result) async {
    if (_downloadingIds.contains(result.id)) {
      StartupLogger.log(
          '[MusicManager] Download already in progress for: ${result.id}');
      return;
    }

    // Mark as downloading
    _downloadingIds.add(result.id);
    _updateProgress(result.id, 0.1, 'Iniciando download...');

    // Fire and forget background process
    _backgroundDownload(result);
  }

  Future<void> _backgroundDownload(SearchResult result) async {
    try {
      StartupLogger.log(
          '[MusicManager] Starting background download for: ${result.title}');

      // Delegate to OfflineDownloadService
      // Note: We don't have fine-grained progress from ffmpeg_kit yet in this simple implementation,
      // but the service handles the heavy lifting.
      _updateProgress(result.id, 0.3, 'Baixando e Convertendo...');

      final success =
          await _downloader.downloadAndConvert(result, result.thumbnail);

      if (success) {
        _updateProgress(result.id, 1.0, 'Concluído', completed: true);

        // Update DB
        result.isDownloaded = true;
        // Note: localPath is determined inside OfflineDownloadService.
        // ideally the service should return the path or we assume standard location.
        // For now, let's assume successful download means it's in the Downloads folder.
        // We might need to refresh local files scan or similar.
        await DatabaseService.instance.saveTrack(result.toJson());
      } else {
        _updateProgress(result.id, 0.0, 'Erro', failed: true);
      }
    } catch (e) {
      StartupLogger.log('[MusicManager] Download failed: $e');
      _updateProgress(result.id, 0.0, 'Falha', failed: true);
    } finally {
      _downloadingIds.remove(result.id);
    }
  }

  void _updateProgress(String id, double progress, String status,
      {bool completed = false, bool failed = false}) {
    final current =
        Map<String, DownloadProgress>.from(_progressController.value);
    if (completed || failed) {
      // Keep completed/failed state for a moment or remove?
      // Usually good to show checkmark.
      // For now let's just update the value.
      current[id] = DownloadProgress(
          id: id,
          progress: progress,
          status: status,
          isCompleted: completed,
          isFailed: failed);
      // Schedule removal if needed, or UI handles it.
      if (completed || failed) {
        Future.delayed(const Duration(seconds: 3), () {
          final updated =
              Map<String, DownloadProgress>.from(_progressController.value);
          updated.remove(id);
          _progressController.add(updated);
        });
      }
    } else {
      current[id] = DownloadProgress(
          id: id,
          progress: progress,
          status: status,
          isCompleted: completed,
          isFailed: failed);
    }
    _progressController.add(current);
  }

  void dispose() {
    _streamer.dispose();
    _progressController.close();
  }
}
