import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:flutter/foundation.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/services/local_duo_service.dart';
import 'package:music_tag_editor/services/equalizer_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/lyrics_service.dart';
import 'package:music_tag_editor/services/startup_logger.dart';
import 'dart:async';

class PlaybackService {
  static PlaybackService? _instance;
  static PlaybackService get instance =>
      _instance ??= PlaybackService._internal();
  static set instance(PlaybackService value) => _instance = value;
  static void resetInstance() => _instance = null;

  PlaybackService._internal() {
    _player = Player();
    _videoController = VideoController(_player);
  }

  @visibleForTesting
  PlaybackService.forTesting({
    Player? player, 
    BaseAudioHandler? handler,
    VideoController? videoController,
  }) {
    _player = player ?? Player();
    _videoController = videoController ?? VideoController(_player);
    if (handler != null) {
      _audioHandler = handler;
    }
  }

  late final Player _player;
  late final VideoController _videoController;

  VideoController get videoController => _videoController;

  final SearchService _searchService = SearchService.instance;

  SearchResult? _currentTrack;
  final List<SearchResult> _queue = [];
  // ignore: unused_field
  Duration _crossfadeDuration = const Duration(seconds: 2);
  List<LyricLine> _currentLyrics = [];
  Timer? _sleepTimer;
  final _sleepTimerController = StreamController<Duration?>.broadcast();
  final _lyricsController = StreamController<List<LyricLine>>.broadcast();
  final _trackController = StreamController<SearchResult?>.broadcast();
  Duration? _sleepTimeLeft;

  SearchResult? get currentTrack => _currentTrack;
  List<SearchResult> get queue => List.unmodifiable(_queue);
  List<LyricLine> get currentLyrics => _currentLyrics;
  Player get player => _player;
  Stream<Duration?> get sleepTimerStream => _sleepTimerController.stream;
  Stream<List<LyricLine>> get lyricsStream => _lyricsController.stream;
  Stream<SearchResult?> get currentTrackStream => _trackController.stream;
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

    _player.stream.track.listen((track) {
      // Logic for track changes if needed via media_kit streams
    });

    _player.stream.error.listen((error) {
      StartupLogger.logError('[PlaybackService] Player Error', error, StackTrace.current);
    });

    _player.stream.playing.listen((playing) {
      _updatePlaybackState();
    });

    _player.stream.position.listen((position) {
      _updatePlaybackState();
    });

    _player.stream.buffer.listen((buffer) {
      _updatePlaybackState();
    });

    // Restore last played track
    try {
      final history = await DatabaseService.instance.getPlayHistory();
      if (history.isNotEmpty) {
        final lastTrackData = history.first;
        final lastTrack = SearchResult.fromJson(lastTrackData);
        _currentTrack = lastTrack;
        _trackController.add(lastTrack);
        
        StartupLogger.log('[PlaybackService] Restored last track metadata: ${lastTrack.title}');

        _restoreAudioSource(lastTrack);
      }
    } catch (e) {
      StartupLogger.log('[PlaybackService] Failed to restore last track: $e');
    }
  }

  late BaseAudioHandler _audioHandler;

  Future<void> _restoreAudioSource(SearchResult track) async {
    try {
      _queue.clear();
      _queue.add(track);
      
      final source = await _createSource(track);
      if (source != null) {
        await _player.open(Media(source), play: false);
      }
      
      _audioHandler.mediaItem.add(MediaItem(
        id: track.id,
        album: track.album ?? 'Unknown Album',
        title: track.title,
        artist: track.artist,
        duration: track.duration != null
            ? Duration(seconds: track.duration!)
            : null,
        artUri: track.thumbnail != null ? Uri.parse(track.thumbnail!) : null,
      ));
      StartupLogger.log('[PlaybackService] Source restored and ready');
    } catch (e) {
      StartupLogger.log('[PlaybackService] Failed to restore source: $e');
    }
  }

  void _updatePlaybackState() {
    _audioHandler.playbackState.add(PlaybackState(
          controls: [
            MediaControl.skipToPrevious,
            if (_player.state.playing) MediaControl.pause else MediaControl.play,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
          },
          androidCompactActionIndices: const [0, 1, 3],
          processingState: _mapProcessingState(),
          playing: _player.state.playing,
          updatePosition: _player.state.position,
          bufferedPosition: _player.state.buffer,
          speed: _player.state.rate,
        ));
  }

  AudioProcessingState _mapProcessingState() {
    if (_player.state.buffering) return AudioProcessingState.buffering;
    if (_player.state.playing) return AudioProcessingState.ready;
    return AudioProcessingState.idle;
  }

  void _onTrackChanged(SearchResult track) {
    _currentTrack = track;
    _trackController.add(track);
    EqualizerService.instance.applyPresetForGenre(track.genre);
    ThemeService.instance.updateThemeFromImage(track.thumbnail);
    DatabaseService.instance.trackPlay(track.id);
    _fetchLyrics(track);

    _audioHandler.mediaItem.add(MediaItem(
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
    StartupLogger.log('[PlaybackService] Playing search result: ${result.title} (${result.platform})');
    _currentTrack = result;

    _queue.clear();
    _queue.add(result);
    
    final source = await _createSource(result);
    if (source != null) {
      await _player.open(Media(source));
      _onTrackChanged(result);
    }

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

  Future<String?> _createSource(SearchResult track) async {
    if (track.localPath != null) {
      StartupLogger.log('[PlaybackService] Playing local file: ${track.localPath}');
      return track.localPath;
    }
    StartupLogger.log('[PlaybackService] Fetching stream URL for: ${track.url}');
    // Logic for highest quality resolution should be in search_service
    final streamUrl = await _searchService.getStreamUrl(track.url);
    if (streamUrl != null) {
      StartupLogger.log('[PlaybackService] Stream URL obtained successfully');
      return streamUrl;
    }
    StartupLogger.log('[PlaybackService] ERROR: Could not get stream URL for ${track.id}');
    return null;
  }

  Future<void> pause({bool fromRemote = false}) async {
    await _player.pause();
    if (!fromRemote) {
      LocalDuoService.instance.sendMessage({
        'type': 'pause',
        'positionMs': _player.state.position.inMilliseconds,
      });
    }
  }

  Future<void> resume({bool fromRemote = false}) async {
    await _player.play();
    if (!fromRemote) {
      LocalDuoService.instance.sendMessage({
        'type': 'play',
        'positionMs': _player.state.position.inMilliseconds,
      });
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _currentTrack = null;
    _trackController.add(null);
  }

  Future<void> seek(Duration position, {bool fromRemote = false}) async {
    await _player.seek(position);
    if (!fromRemote) {
      LocalDuoService.instance.sendMessage({
        'type': 'seek',
        'positionMs': position.inMilliseconds,
      });
    }
  }

  Future<void> next() async {
    if (_queue.isNotEmpty) {
      final nextTrack = _queue.removeAt(0);
      await playSearchResult(nextTrack);
    }
  }

  Future<void> previous() async {
    await _player.seek(Duration.zero);
  }

  Future<void> toggleShuffle() async {
    await _player.setShuffle(!_player.state.shuffle);
  }

  Future<void> toggleRepeat() async {
    final mode = _player.state.playlistMode;
    if (mode == PlaylistMode.none) {
      await _player.setPlaylistMode(PlaylistMode.loop);
    } else if (mode == PlaylistMode.loop) {
      await _player.setPlaylistMode(PlaylistMode.single);
    } else {
      await _player.setPlaylistMode(PlaylistMode.none);
    }
  }

  void playFromRemote(Duration position) {

    _player.seek(position);
    _player.play();
  }

  void pauseFromRemote() {
    _player.pause();
  }

  Future<void> playLocalFile(String path, SearchResult track) async {
    _currentTrack = track;
    EqualizerService.instance.applyPresetForGenre(track.genre);
    await _player.open(Media(path));
    _trackController.add(track);
  }

  Future<void> addToQueue(SearchResult track, {bool fromRemote = false}) async {
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

  void updateCrossfadeDuration(Duration duration) {
    _crossfadeDuration = duration;
  }

  void dispose() {
    _sleepTimer?.cancel();
    _sleepTimerController.close();
    _lyricsController.close();
    _trackController.close();
    _player.dispose();
  }
}

class MusicAudioHandler extends BaseAudioHandler {
  final PlaybackService _service;

  MusicAudioHandler(this._service);

  @override
  Future<void> updateMediaItem(MediaItem mediaItem) async => this.mediaItem.add(mediaItem);
  Future<void> updatePlaybackState(PlaybackState state) async => playbackState.add(state);

  @override
  Future<void> play() => _service.resume();

  @override
  Future<void> pause() => _service.pause();

  @override
  Future<void> stop() => _service.stop();

  @override
  Future<void> skipToNext() => _service.next();

  @override
  Future<void> skipToPrevious() => _service.previous();

  @override
  Future<void> seek(Duration position) => _service.seek(position);
}
