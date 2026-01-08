import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:music_hub/core/services/startup_logger.dart';

class YouTubeStreamerService {
  final YoutubeExplode _yt = YoutubeExplode();

  /// Busca o melhor ID de vídeo priorizando áudio limpo de estúdio.
  /// Retorna a URL direta de streaming para ser usada no just_audio.
  Future<String?> getStreamUrl(String query,
      {bool allowExplicit = false}) async {
    try {
      // Estratégia de busca em cascata
      // final searchTerms = [
      //   '$query topic',           // 1. Áudio do álbum (Melhor)
      //   allowExplicit ? '$query explicit' : '$query official audio', // 2. Audio Oficial
      //   '$query music video'          // 3. Último recurso (tem intro de vídeo)
      // ];

      // Tenta buscar o melhor candidato
      // Por enquanto simplificado para usar o primeiro termo de busca que é o mais forte
      StartupLogger.log('[YouTubeStreamer] Searching stream for: $query');
      final results = await _yt.search.search('$query topic');
      final videoId = await _filterBestVideo(results);

      if (videoId == null) {
        StartupLogger.log('[YouTubeStreamer] No valid video found for: $query');
        return null;
      }

      StartupLogger.log('[YouTubeStreamer] Found video ID: $videoId');

      // Obtém manifesto e extrai o áudio de maior qualidade
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final streamInfo = manifest.audioOnly.withHighestBitrate();

      // Retorna a URL de streaming
      return streamInfo.url.toString();
    } catch (e) {
      StartupLogger.log('[YouTubeStreamer] Erro ao extrair stream YouTube: $e');
      return null;
    }
  }

  /// Filtra os resultados para pegar apenas "Topic" ou Oficiais
  Future<String?> _filterBestVideo(List<Video> results) async {
    for (final video in results) {
      if (video.duration == null || video.duration!.inSeconds < 60) continue;

      final channel = video.author.toLowerCase();
      final title = video.title.toLowerCase();

      // Prioridade 1: Topic (Áudio Puro)
      if (channel.endsWith(' - topic')) {
        return video.id.value;
      }

      // Prioridade 2: Official Audio
      if (title.contains('official audio') && !title.contains('lyrics')) {
        return video.id.value;
      }
    }

    // Fallback: Retorna o primeiro resultado se não for muito curto
    if (results.isNotEmpty) {
      return results.first.id.value;
    }

    // Retorna null se não achar nada satisfatório
    return null;
  }

  void dispose() => _yt.close();
}
