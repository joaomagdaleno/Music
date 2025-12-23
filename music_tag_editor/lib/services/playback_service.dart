import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/services/local_duo_service.dart';
import 'package:music_tag_editor/services/equalizer_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/lyrics_service.dart';
import 'package:meta/meta.dart';
import 'dart:async';

class PlaybackService {
  static PlaybackService? _instance;
  static PlaybackService get instance =>
      _instance ??= PlaybackService._internal();

  @visibleForTesting
  static set instance(PlaybackService mock) => _instance = mock;

  @visibleForTesting
  factory PlaybackService.forTesting(
      {AudioPlayer? player, AudioHandler? handler}) {
    return PlaybackService._internal(player: player, handler: handler);
  }

  PlaybackService._internal({AudioPlayer? player, AudioHandler? handler}) {
    _player = player ??
        AudioPlayer(
          audioPipeline: AudioPipeline(
            androidAudioEffects: [EqualizerService.instance.equalizer],
          ),
        );
    if (handler != null) _audioHandler = handler;
  }

  late AudioPlayer _player;

  @visibleForTesting
  set player(AudioPlayer mock) => _player = mock;
  late AudioHandler _audioHandler;

  @visibleForTesting
  set audioHandler(AudioHandler mock) => _audioHandler = mock;
  final SearchService _searchService = SearchService();

  SearchResult? _currentTrack;
  final List<SearchResult> _queue = [];
  ConcatenatingAudioSource? _playlist;
  Duration _crossfadeDuration = const Duration(seconds: 3);
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
    _audioHandler = await AudioService.init(
      builder: () => MusicAudioHandler(this),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.music.app.channel.audio',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationOngoing: true,
      ),
    );

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Load crossfade duration
    final savedDuration =
        await DatabaseService.instance.loadCrossfadeDuration();
    _crossfadeDuration = Duration(seconds: savedDuration);

    _player.currentIndexStream.listen((index) {
      if (index != null && _queue.isNotEmpty && index < _queue.length) {
        _onTrackChanged(_queue[index]);
      }
    });

    _player.processingStateStream.listen((state) {
      _updatePlaybackState();
    });
    _player.playingStream.listen((playing) {
      _updatePlaybackState();
    });
    _player.positionStream.listen((position) {
      _updatePlaybackState();
    });
  }

  void _updatePlaybackState() {
    (_audioHandler as BaseAudioHandler).playbackState.add(PlaybackState(
          controls: [
            MediaControl.skipToPrevious,
            if (_player.playing) MediaControl.pause else MediaControl.play,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
          },
          androidCompactActionIndices: const [0, 1, 3],
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState]!,
          playing: _player.playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: _player.currentIndex,
        ));
  }

  void _onTrackChanged(SearchResult track) {
    _currentTrack = track;
    EqualizerService.instance.applyPresetForGenre(track.genre);
    ThemeService.instance.updateThemeFromImage(track.thumbnail);
    DatabaseService.instance.trackPlay(track.id);
    _fetchLyrics(track);

    (_audioHandler as BaseAudioHandler).mediaItem.add(MediaItem(
          id: track.id,
          album: track.album ?? 'Unknown Album',
          title: track.title,
          artist: track.artist,
          duration: track.duration != null
              ? Duration(seconds: track.duration!)
              : null,
          artUri: track.thumbnail != null ? Uri.parse(track.thumbnail!) : null,
        ));
  }

  Future<void> playSearchResult(SearchResult result,
      {bool fromRemote = false}) async {
    _currentTrack = result;

    // Clear queue and start fresh for a single play
    _queue.clear();
    _queue.add(result);
    _playlist =
        ConcatenatingAudioSource(children: [await _createSource(result)]);

    await _player.setAudioSource(_playlist!);
    _onTrackChanged(result);
    _player.play();

    if (!fromRemote) {
      LocalDuoService.instance.sendMessage({
        'type': 'track',
        'track': result.toJson(),
      });
      if (result.localPath != null) {
        LocalDuoService.instance.sendFile(result.localPath!);
      }
    }
  }

  Future<AudioSource> _createSource(SearchResult track) async {
    if (track.localPath != null) {
      return AudioSource.uri(Uri.file(track.localPath!));
    }
    final streamUrl = await _searchService.getStreamUrl(track.url);
    if (streamUrl != null) {
      return AudioSource.uri(Uri.parse(streamUrl));
    }
    throw Exception('Could not get stream URL');
  }

  Future<void> fadeOutAndNext() async {
    if (_crossfadeDuration.inMilliseconds > 0) {
      for (double i = 1.0; i >= 0; i -= 0.1) {
        _player.setVolume(i);
        await Future.delayed(
            Duration(milliseconds: _crossfadeDuration.inMilliseconds ~/ 10));
      }
    }
    _player.seekToNext();
    _player.setVolume(1.0);
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

  Future<void> addToQueue(SearchResult track, {bool fromRemote = false}) async {
    _queue.add(track);
    if (_playlist != null) {
      _playlist!.add(await _createSource(track));
    }
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

  void updateCrossfadeDuration(Duration duration) {
    _crossfadeDuration = duration;
  }

  void dispose() {
    _sleepTimer?.cancel();
    _sleepTimerController.close();
    _lyricsController.close();
    _player.dispose();
  }
}

class MusicAudioHandler extends BaseAudioHandler {
  final PlaybackService _service;

  MusicAudioHandler(this._service);

  @override
  Future<void> play() => _service.resume();

  @override
  Future<void> pause() => _service.pause();

  @override
  Future<void> stop() => _service.stop();

  @override
  Future<void> skipToNext() => _service._player.seekToNext();

  @override
  Future<void> skipToPrevious() => _service._player.seekToPrevious();

  @override
  Future<void> seek(Duration position) => _service.seek(position);
}

