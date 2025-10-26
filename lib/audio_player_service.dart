import 'package:just_audio/just_audio.dart';
import 'main.dart'; // To get MusicTrack class

class AudioPlayerService {
  // Singleton pattern to ensure only one instance of the player.
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  ConcatenatingAudioSource? _playlist;

  // Streams for the UI to listen to.
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<SequenceState?> get sequenceStateStream => _audioPlayer.sequenceStateStream;
  Stream<double> get volumeStream => _audioPlayer.volumeStream;
  Stream<LoopMode> get loopModeStream => _audioPlayer.loopModeStream;

  // Getter for the current playlist
  List<MusicTrack> get currentPlaylist {
    if (_playlist == null) return [];
    return _playlist!.children.map((source) => (source as UriAudioSource).tag as MusicTrack).toList();
  }


  // Methods to control the player.
  Future<void> playPlaylist(List<MusicTrack> tracks, int initialIndex) async {
    if (tracks.isEmpty) return;

    _playlist = ConcatenatingAudioSource(
      children: tracks.map((track) => AudioSource.uri(
        Uri.file(track.filePath),
        tag: track,
      )).toList(),
    );

    try {
      await _audioPlayer.setAudioSource(_playlist!, initialIndex: initialIndex);
      await _audioPlayer.play();
    } catch (e) {
      print("Error playing playlist: $e");
    }
  }

  // Utility method to get the duration of a file
  Future<Duration?> getDuration(String filePath) async {
    try {
      final tempPlayer = AudioPlayer();
      final duration = await tempPlayer.setFilePath(filePath);
      await tempPlayer.dispose();
      return duration;
    } catch (e) {
      print("Error getting duration: $e");
      return null;
    }
  }

  Future<void> play() async => await _audioPlayer.play();
  Future<void> pause() async => await _audioPlayer.pause();
  Future<void> seek(Duration position) async => await _audioPlayer.seek(position);
  Future<void> seekToNext() async => await _audioPlayer.seekToNext();
  Future<void> seekToPrevious() async => await _audioPlayer.seekToPrevious();
  Future<void> stop() async => await _audioPlayer.stop();
  Future<void> setVolume(double volume) async => await _audioPlayer.setVolume(volume);
  Future<void> setLoopMode(LoopMode loopMode) async => await _audioPlayer.setLoopMode(loopMode);


  void dispose() {
    _audioPlayer.dispose();
  }
}
