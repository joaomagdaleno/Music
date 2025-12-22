import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'download_service.dart';
import 'search_service.dart';
import 'local_duo_service.dart';
import 'equalizer_service.dart';
import 'theme_service.dart';
import 'database_service.dart';
import 'lyrics_service.dart';
import 'dart:async';

class PlaybackService {
  static final PlaybackService instance = PlaybackService._internal();
  PlaybackService._internal();

  final AudioPlayer _player = AudioPlayer(
    audioPipeline: AudioPipeline(
      androidAudioEffects: [EqualizerService.instance.equalizer],
    ),
  );
  final SearchService _searchService = SearchService();

  SearchResult? _currentTrack;
  final List<SearchResult> _queue = [];
  List<LyricLine> _currentLyrics = [];
  Timer? _sleepTimer;
  final _sleepTimerController = StreamController<Duration?>.broadcast();
  final _lyricsController = StreamController<List<LyricLine>>.broadcast();
  Duration? _sleepTimeLeft;

  SearchResult? get currentTrack => _currentTrack;
  List<SearchResult> get queue => List.unmodifiable(_queue);
  List<LyricLine> get currentLyrics => _currentLyrics;
  AudioPlayer get player => _player;
  Stream<Duration?> get sleepTimerStream => _sleepTimerController.stream;
  Stream<List<LyricLine>> get lyricsStream => _lyricsController.stream;
  Duration? get sleepTimeLeft => _sleepTimeLeft;

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _playNext();
      }
    });
  }

  void _playNext() {
    if (_queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      playSearchResult(next);
    }
  }

  Future<void> playSearchResult(SearchResult result,
      {bool fromRemote = false}) async {
    _currentTrack = result;

    if (!fromRemote) {
      LocalDuoService.instance.sendMessage({
        'type': 'track',
        'track': result.toJson(),
      });
      if (result.localPath != null) {
        LocalDuoService.instance.sendFile(result.localPath!);
      }
    }

    if (result.localPath != null) {
      await EqualizerService.instance.applyPresetForGenre(result.genre);
      ThemeService.instance.updateThemeFromImage(result.thumbnail);
      DatabaseService.instance.trackPlay(result.id);
      _fetchLyrics(result);
      await _player.setFilePath(result.localPath!);
      _player.play();
      return;
    }

    final streamUrl = await _searchService.getStreamUrl(result.url);
    if (streamUrl != null) {
      await EqualizerService.instance.applyPresetForGenre(result.genre);
      ThemeService.instance.updateThemeFromImage(result.thumbnail);
      DatabaseService.instance.trackPlay(result.id);
      _fetchLyrics(result);
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

  void playLocalFile(String path, SearchResult track) {
    _currentTrack = track;
    EqualizerService.instance.applyPresetForGenre(track.genre);
    _player.setFilePath(path);
    _player.play();
  }

  void addToQueue(SearchResult track, {bool fromRemote = false}) {
    _queue.add(track);
    if (!fromRemote) {
      LocalDuoService.instance.sendMessage({
        'type': 'add_to_queue',
        'track': track.toJson(),
      });
    }
  }

  void clearQueue() {
    _queue.clear();
  }

  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepTimeLeft = duration;
    _sleepTimerController.add(_sleepTimeLeft);

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sleepTimeLeft != null) {
        if (_sleepTimeLeft!.inSeconds <= 0) {
          stop();
          cancelSleepTimer();
        } else {
          _sleepTimeLeft = Duration(seconds: _sleepTimeLeft!.inSeconds - 1);
          _sleepTimerController.add(_sleepTimeLeft);
        }
      }
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimeLeft = null;
    _sleepTimerController.add(null);
  }

  Future<void> _fetchLyrics(SearchResult track) async {
    _currentLyrics = [];
    _lyricsController.add([]);
    final lyrics =
        await LyricsService.instance.fetchLyrics(track.title, track.artist);
    _currentLyrics = lyrics;
    _lyricsController.add(lyrics);
  }

  void dispose() {
    _sleepTimer?.cancel();
    _sleepTimerController.close();
    _lyricsController.close();
    _player.dispose();
  }
}
