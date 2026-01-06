import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:music_hub/features/library/models/search_models.dart' as model;
import 'package:music_hub/core/services/startup_logger.dart';
import 'package:path/path.dart' as p;

class OfflineDownloadService {
  final YoutubeExplode _yt = YoutubeExplode();

  /// Baixa e converte a música para MP3 em background.
  /// [searchResult] é o modelo que você já tem no seu projeto.
  Future<bool> downloadAndConvert(model.SearchResult searchResult, String? coverUrl) async {
    try {
      StartupLogger.log('[OfflineDownload] Starting download for: ${searchResult.title}');

      // 1. Prepara caminhos
      final tempDir = await getTemporaryDirectory();
      final docDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory(p.join(docDir.path, 'Downloads'));
       if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      // Nome limpo do arquivo
      final safeTitle = _sanitizeFilename(searchResult.title);
      final safeArtist = _sanitizeFilename(searchResult.artist);
      final fileName = '$safeArtist - $safeTitle.mp3';
      final finalFile = File(p.join(downloadsDir.path, fileName));
      
      // Arquivo temporário (formato nativo WebM do YouTube)
      final tempWebM = File(p.join(tempDir.path, '${searchResult.id}.webm'));
      // Arquivo temporário da capa
      final tempCover = File(p.join(tempDir.path, '${searchResult.id}_cover.jpg'));

      // 2. Baixa o áudio nativo
      StartupLogger.log('[OfflineDownload] Downloading native audio...');
      final manifest = await _yt.videos.streamsClient.getManifest(searchResult.id);
      final audioStream = manifest.audioOnly.withHighestBitrate();
      final sink = tempWebM.openWrite();
      await _yt.videos.streamsClient.get(audioStream).pipe(sink);
      await sink.close();

      // 3. Baixa a Capa (Se fornecida ou usa placeholder)
      // final coverPath = tempCover.path; // Unused
      if (coverUrl != null && coverUrl.isNotEmpty) {
        StartupLogger.log('[OfflineDownload] Downloading cover art...');
        final response = await http.get(Uri.parse(coverUrl));
        await tempCover.writeAsBytes(response.bodyBytes);
      } else {
         // Se não tiver capa, tenta usar do próprio YouTube se disponivel
         if (searchResult.thumbnail != null) {
            final ytThumbResponse = await http.get(Uri.parse(searchResult.thumbnail!));
            await tempCover.writeAsBytes(ytThumbResponse.bodyBytes);
         }
      }

      // 4. Conversão FFmpeg (Background - Não trava o app)
      StartupLogger.log('[OfflineDownload] Starting FFmpeg conversion...');
      
      final command = [
        '-y',               // Sobrescreve se existir
        '-i', '"${tempWebM.path}"', // Entrada (WebM)
        '-i', '"${tempCover.path}"', // Entrada (Capa)
        '-map', '0:a',       // Seleciona apenas áudio do WebM
        '-map', '1:0',       // Seleciona a capa
        '-c:a', 'libmp3lame', // Codec MP3
        '-b:a', '320k',       // Bitrate Alta
        '-id3v2_version', '3', // Tags ID3 Compatíveis
        '-metadata', 'title="${searchResult.title}"',
        '-metadata', 'artist="${searchResult.artist}"',
        '-metadata:s:v', 'title="Album cover"',
        '-metadata:s:v', 'comment="Cover (front)"',
        '"${finalFile.path}"'      // Saída
      ].join(' ');

      // Wrap in executeAsync to not block UI
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        StartupLogger.log('[OfflineDownload] ✅ SUCCESS: ${finalFile.path}');
        
        // Limpeza
        if (await tempWebM.exists()) await tempWebM.delete();
        if (await tempCover.exists()) await tempCover.delete();
        
        return true;
      } else {
        StartupLogger.log('[OfflineDownload] ❌ FFmpeg failed. Logs:');
        final logs = await session.getLogs();
        for (final log in logs) {
          StartupLogger.log(log.getMessage());
        }
        
        if (await tempWebM.exists()) await tempWebM.delete(); 
        if (await tempCover.exists()) await tempCover.delete();
        return false;
      }

    } catch (e) {
      StartupLogger.log('[OfflineDownload] Fatal error: $e');
      return false;
    }
  }

  String _sanitizeFilename(String name) => name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

  void dispose() => _yt.close();
}
