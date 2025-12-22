import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'download_service.dart';
import 'search_service.dart';
import 'local_duo_service.dart';

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

  Future<void> playSearchResult(SearchResult result,
      {bool fromRemote = false}) async {
    _currentTrack = result;

    if (!fromRemote) {
      LocalDuoService.instance.sendMessage({
        'type': 'track',
        'track': result.toJson(),
      });
    }

    final streamUrl = await _searchService.getStreamUrl(result.url);
    if (streamUrl != null) {
      await _player.setUrl(streamUrl);
      _player.play();
    } else {
      throw Exception('Could not get stream URL');
    }
  }

  Future<void> pause({bool fromRemote = false}) async {
    await _player.pause();
    if (!fromRemote) {
      LocalDuoService.instance.sendMessage({
        'type': 'pause',
        'positionMs': _player.position.inMilliseconds,
      });
    }
  }

  Future<void> resume({bool fromRemote = false}) async {
    await _player.play();
    if (!fromRemote) {
      LocalDuoService.instance.sendMessage({
        'type': 'play',
        'positionMs': _player.position.inMilliseconds,
      });
    }
  }

  Future<void> stop() async => await _player.stop();

  Future<void> seek(Duration position, {bool fromRemote = false}) async {
    await _player.seek(position);
    if (!fromRemote) {
      LocalDuoService.instance.sendMessage({
        'type': 'seek',
        'positionMs': position.inMilliseconds,
      });
    }
  }

  // Remote controls
  void playFromRemote(Duration position) {
    _player.seek(position);
    _player.play();
  }

  void pauseFromRemote() {
    _player.pause();
  }

  void dispose() {
    _player.dispose();
  }
}
