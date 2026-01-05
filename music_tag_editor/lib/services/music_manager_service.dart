import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:music_tag_editor/models/search_models.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/metadata_aggregator_service.dart';
import 'package:music_tag_editor/services/download/metadata_embedder.dart';
import 'package:music_tag_editor/services/startup_logger.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:path/path.dart' as p;

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

  final yt.YoutubeExplode _yt = yt.YoutubeExplode();
  final MetadataEmbedder _embedder = MetadataEmbedder();
  final Set<String> _downloadingIds = {};
  
  final _progressController = BehaviorSubject<Map<String, DownloadProgress>>.seeded({});
  Stream<Map<String, DownloadProgress>> get progressStream => _progressController.stream;

  void _updateProgress(String id, double progress, String status, {bool completed = false, bool failed = false}) {
    final current = Map<String, DownloadProgress>.from(_progressController.value);
    if (completed || failed) {
      current.remove(id);
    } else {
      current[id] = DownloadProgress(id: id, progress: progress, status: status, isCompleted: completed, isFailed: failed);
    }
    _progressController.add(current);
  }

  /// Plays the track instantly via streaming. No disk usage.
  Future<void> playInstant(SearchResult result) async {
    StartupLogger.log('[MusicManager] Instant play requested for: ${result.title}');
    await PlaybackService.instance.playSearchResult(result);
  }

  /// Downloads the track in the background, converts to 320kbps MP3, and embeds artwork.
  Future<void> downloadTrack(SearchResult result) async {
    if (_downloadingIds.contains(result.id)) {
      StartupLogger.log('[MusicManager] Download already in progress for: ${result.id}');
      return;
    }

    if (result.isDownloaded && result.localPath != null) {
      if (await File(result.localPath!).exists()) {
        StartupLogger.log('[MusicManager] Track already downloaded: ${result.id}');
        return;
      }
    }

    _downloadingIds.add(result.id);
    _backgroundDownload(result); // Fire and forget
  }

  Future<void> _backgroundDownload(SearchResult result) async {
    try {
      _updateProgress(result.id, 0.05, 'Buscando metadados...');
      StartupLogger.log('[MusicManager] Starting background processing for: ${result.title}');

      // 1. Fetch clean metadata and artwork URL
      final meta = await MetadataAggregatorService.instance.aggregateMetadata(
        result.title,
        result.artist,
      );

      // 2. Prepare paths
      final tempDir = await getTemporaryDirectory();
      final tempAudioPath = p.join(tempDir.path, '${result.id}_raw');
      final tempArtworkPath = p.join(tempDir.path, '${result.id}_cover.jpg');

      // 3. Download native audio stream (fastest)
      _updateProgress(result.id, 0.1, 'Baixando áudio...');
      StartupLogger.log('[MusicManager] Downloading native stream...');
      final manifest = await _yt.videos.streamsClient.getManifest(result.id);
      final audioStream = manifest.audioOnly.withHighestBitrate();
      
      final audioFile = File(tempAudioPath);
      final audioSink = audioFile.openWrite();
      await _yt.videos.streamsClient.get(audioStream).pipe(audioSink);
      await audioSink.close();

      // 4. Download artwork
      String? artworkPath;
      if (meta.thumbnail != null) {
        _updateProgress(result.id, 0.5, 'Baixando capa...');
        StartupLogger.log('[MusicManager] Downloading artwork...');
        try {
          final response = await http.get(Uri.parse(meta.thumbnail!));
          if (response.statusCode == 200) {
            await File(tempArtworkPath).writeAsBytes(response.bodyBytes);
            artworkPath = tempArtworkPath;
          }
        } catch (e) {
          StartupLogger.log('[MusicManager] Artwork download failed: $e');
        }
      }

      // 5. Convert to 320kbps MP3 and embed metadata/artwork
      _updateProgress(result.id, 0.7, 'Convertendo para MP3...');
      StartupLogger.log('[MusicManager] Converting and embedding metadata...');
      
      // Target directory in AppData/Documents/Downloads
      final docDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory(p.join(docDir.path, 'Downloads'));
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final safeTitle = (meta.title ?? result.title).replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final safeArtist = (meta.artist ?? result.artist).replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final finalFileName = '$safeArtist - $safeTitle.mp3';
      final finalPath = p.join(downloadsDir.path, finalFileName);

      final success = await _embedder.embed(
        tempAudioPath,
        meta,
        artworkPath: artworkPath,
        convertToMp3: true,
      );

      if (success) {
        _updateProgress(result.id, 0.95, 'Finalizando...');
        // Embedder renames result to tempDir/id_raw.mp3
        final taggedTempPath = p.join(tempDir.path, '${result.id}_raw.mp3');
        if (await File(taggedTempPath).exists()) {
          await File(taggedTempPath).rename(finalPath);
          StartupLogger.log('[MusicManager] Final MP3 saved: $finalPath');

          // Update result and DB
          result.localPath = finalPath;
          result.isDownloaded = true;
          await DatabaseService.instance.saveTrack(result.toJson());
          
          StartupLogger.log('[MusicManager] Database updated for: ${result.id}');
          _updateProgress(result.id, 1.0, 'Concluído', completed: true);
        }
      } else {
        _updateProgress(result.id, 1.0, 'Erro na conversão', failed: true);
      }

      // Cleanup
      if (artworkPath != null && await File(artworkPath).exists()) {
        await File(artworkPath).delete();
      }
      if (await audioFile.exists()) {
        await audioFile.delete();
      }

    } catch (e) {
      StartupLogger.log('[MusicManager] Background processing failed for ${result.id}: $e');
      _updateProgress(result.id, 1.0, 'Falha no download', failed: true);
    } finally {
      _downloadingIds.remove(result.id);
    }
  }

  void dispose() {
    _yt.close();
  }
}
