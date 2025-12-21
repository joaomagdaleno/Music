import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'download_service.dart';
import 'search_service.dart';

class PlaybackService {
  static final PlaybackService instance = PlaybackService._internal();
  PlaybackService._internal();

  final AudioPlayer _player = AudioPlayer();
  final SearchService _searchService = SearchService();

  SearchResult? _currentTrack;

  SearchResult? get currentTrack => _currentTrack;
  AudioPlayer get player => _player;

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> playSearchResult(SearchResult result) async {
    _currentTrack = result;

    // Get stream URL (might be slow, so we could show loading in UI)
    final streamUrl = await _searchService.getStreamUrl(result.url);
    if (streamUrl != null) {
      await _player.setUrl(streamUrl);
      _player.play();
    } else {
      throw Exception('Could not get stream URL');
    }
  }

  Future<void> pause() async => await _player.pause();
  Future<void> resume() async => await _player.play();
  Future<void> stop() async => await _player.stop();
  Future<void> seek(Duration position) async => await _player.seek(position);

  void dispose() {
    _player.dispose();
  }
}
