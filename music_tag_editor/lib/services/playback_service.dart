import 'package:media_kit/media_kit.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/models/search_models.dart';
import 'package:music_tag_editor/services/local_duo_service.dart';
import 'package:music_tag_editor/services/equalizer_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/lyrics_service.dart';
import 'package:music_tag_editor/services/metadata_service.dart';
import 'package:music_tag_editor/services/metadata_aggregator_service.dart';
import 'package:music_tag_editor/services/startup_logger.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';

class PlaybackService {
  static PlaybackService? _instance;
  static PlaybackService get instance =>
      _instance ??= PlaybackService._internal();
  static set instance(PlaybackService value) => _instance = value;
  static void resetInstance() => _instance = null;

  PlaybackService._internal() {
    _player = Player();
    _applyStreamingConfigs();
  }

  void _applyStreamingConfigs() {
    if (_player.platform is NativePlayer) {
      final player = _player.platform as NativePlayer;
      player.setProperty('user-agent',
          'Mozilla/5.0 (Android 14; Mobile; rv:128.0) Gecko/128.0 Firefox/128.0');
      player.setProperty('referrer', 'https://www.youtube.com/');
      player.setProperty(
          'demuxer-max-bytes', '67108864'); // 64MB for better caching
      player.setProperty('demuxer-readahead-secs', '60');
      player.setProperty('ytdl-format', 'bestaudio/best');
    }
  }

  @visibleForTesting
  PlaybackService.forTesting({
    Player? player,
    BaseAudioHandler? handler,
  }) {
    _player = player ?? Player();
    if (handler != null) {
      _audioHandler = handler;
    }
  }

  late final Player _player;

  final SearchService _searchService = SearchService.instance;

  SearchResult? _currentTrack;
  final List<SearchResult> _queue = [];
  // ignore: unused_field
  Duration _crossfadeDuration = const Duration(seconds: 2);
  List<LyricLine> _currentLyrics = [];
  Timer? _sleepTimer;
  StreamSubscription? _selfHealingSubscription;
  final _sleepTimerController = StreamController<Duration?>.broadcast();
  final _lyricsController = StreamController<List<LyricLine>>.broadcast();
  final _trackController = BehaviorSubject<SearchResult?>();
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

    // Initialize wakelock state
    WakelockPlus.enable(); // Keep awake during init/prep

    // Load crossfade duration
    final savedDuration =
        await DatabaseService.instance.loadCrossfadeDuration();
    _crossfadeDuration = Duration(seconds: savedDuration);

    _player.stream.track.listen((track) {
      // Logic for track changes if needed via media_kit streams
    });

    _player.stream.error.listen((error) {
      StartupLogger.logError(
          '[PlaybackService] Player Error', error, StackTrace.current);
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

        StartupLogger.log(
            '[PlaybackService] Restored last track metadata: ${lastTrack.title}');

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
        duration:
            track.duration != null ? Duration(seconds: track.duration!) : null,
        artUri: track.thumbnail != null ? Uri.parse(track.thumbnail!) : null,
      ));
      StartupLogger.log('[PlaybackService] Source restored and ready');
    } catch (e) {
      StartupLogger.log('[PlaybackService] Failed to restore source: $e');
    }
  }

  void _updatePlaybackState() {
    final playing = _player.state.playing;

    // Manage wakelock based on playback state
    if (playing) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }

    _audioHandler.playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: _mapProcessingState(),
      playing: playing,
      updatePosition: _player.state.position,
      bufferedPosition: _player.state.buffer,
      speed: _player.state.rate,
    ));
  }

  AudioProcessingState _mapProcessingState() {
    if (_player.state.buffering) return AudioProcessingState.buffering;
    if (_player.state.completed) return AudioProcessingState.completed;
    // Always ready if loaded, even if paused
    return AudioProcessingState.ready;
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
      duration:
          track.duration != null ? Duration(seconds: track.duration!) : null,
      artUri: track.thumbnail != null ? Uri.parse(track.thumbnail!) : null,
    ));
  }

  Future<void> toggleFavorite() async {
    if (_currentTrack == null) return;
    final newState = !_currentTrack!.isVault;
    _currentTrack!.isVault = newState;
    await DatabaseService.instance.toggleVault(_currentTrack!.id, newState);
    _trackController.add(_currentTrack);
  }

  Future<void> playSearchResult(SearchResult result,
      {bool fromRemote = false}) async {
    StartupLogger.log(
        '[PlaybackService] Playing search result: ${result.title} (${result.platform})');
    _currentTrack = result;

    _queue.clear();
    _queue.add(result);

    // Parallelize stream extraction and metadata enrichment for faster start
    final extractionFuture = _createSource(result);
    final enrichmentFuture = _enrichMetadata(result);

    final extractionResults =
        await Future.wait([extractionFuture, enrichmentFuture]);
    String? source = extractionResults[0] as String?;

    if (source == null && result.platform == MediaPlatform.youtube) {
      StartupLogger.log(
          '[PlaybackService] Primary source failed. Attempting Ultimate Recovery Loop...');
      // Ultimate Recovery Loop: Search for candidates
      final query = '${result.artist} ${result.title}';
      final candidates = await SearchService.instance.searchAll(query);

      for (final candidate in candidates.take(5)) {
        if (candidate.id == result.id) continue;
        StartupLogger.log(
            '[PlaybackService] Trying alternate candidate: ${candidate.title} (${candidate.id})');
        source = await _createSource(candidate);
        if (source != null) {
          result = candidate; // Update current track to the working candidate
          _currentTrack = result;
          break;
        }
      }
    }

    if (source != null) {
      // Add User-Agent to prevent 403 errors on direct streams
      final headers = source.startsWith('http')
          ? {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36'
            }
          : null;

      try {
        await _player.open(Media(source, httpHeaders: headers));
        _onTrackChanged(result);
        _setupSelfHealing(result.id);
      } catch (e) {
        StartupLogger.logError('[PlaybackService] Failed to open player', e,
            StackTrace.current);
        // If it fails here, we could potentially retry with next candidate...
      }
    } else {
      StartupLogger.log('[PlaybackService] CRITICAL: No playable source found');
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

  void _setupSelfHealing(String trackId) {
    _selfHealingSubscription?.cancel();
    // Listen for unexpected stops (mid-track idling)
    _selfHealingSubscription = _player.stream.playing.listen((isPlaying) async {
      if (!isPlaying &&
          _player.state.position > Duration.zero &&
          !_player.state.completed &&
          _currentTrack?.id == trackId) {
        StartupLogger.log(
            '[PlaybackService] Unexpected pause detected. Checking for stream expiration...');
        // Wait a bit to see if it's just a buffer lag or a real failure
        await Future.delayed(const Duration(seconds: 2));
        if (!_player.state.playing &&
            _player.state.position > Duration.zero &&
            !_player.state.completed) {
          StartupLogger.log('[PlaybackService] Stream seems dead. Healing...');
          final lastPos = _player.state.position;
          final source = await _createSource(_currentTrack!);
          if (source != null) {
            await _player.open(Media(source), play: true);
            await _player.seek(lastPos);
            StartupLogger.log('[PlaybackService] Self-healing successful');
          }
        }
      }
    });
  }

  Future<void> _enrichMetadata(SearchResult result) async {
    try {
      final aggregator = MetadataAggregatorService.instance;
      final metadata = await aggregator.aggregateMetadata(
        result.title,
        result.artist,
        durationMs: (result.duration ?? 0) * 1000,
      );

      result.isDownloaded = false; // Reset temporary flags if needed
      // Prefer official metadata if found
      final enrichedResult = SearchResult(
        id: result.id,
        title: metadata.title ?? result.title,
        artist: metadata.artist ?? result.artist,
        album: metadata.album ?? result.album,
        thumbnail: metadata.thumbnail ?? result.thumbnail,
        duration: result.duration,
        url: result.url,
        platform: result.platform,
        localPath: result.localPath,
        genre: metadata.genre ?? result.genre,
        hifiSource: result.hifiSource,
        hifiQuality: result.hifiQuality,
        isVault: result.isVault,
        isOfficial: result.isOfficial,
      );

      // Update current track if it's still the same ID
      if (_currentTrack?.id == result.id) {
        _currentTrack = enrichedResult;
        _trackController.add(enrichedResult);
        DatabaseService.instance.saveTrack(enrichedResult.toJson());
      }
    } catch (e) {
      StartupLogger.log('[PlaybackService] Metadata enrichment failed: $e');
    }
  }

  Future<String?> _createSource(SearchResult track) async {
    if (track.localPath != null) {
      StartupLogger.log(
          '[PlaybackService] Playing local file: ${track.localPath}');
      return track.localPath;
    }
    StartupLogger.log(
        '[PlaybackService] Fetching stream URL for: ${track.url}');
    // Logic for highest quality resolution should be in search_service
    final streamUrl = await _searchService.getStreamUrl(
      track.url,
      platform: track.platform,
    );
    if (streamUrl != null) {
      StartupLogger.log('[PlaybackService] Stream URL obtained successfully');
      return streamUrl;
    }
    StartupLogger.log(
        '[PlaybackService] ERROR: Could not get stream URL for ${track.id}');
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

    // 1. Try to read from local file if it exists
    if (track.url.startsWith('/') || track.url.startsWith('file://')) {
      try {
        final path = track.url.replaceFirst('file://', '');
        final metadata = await MetadataService().readMetadata(path);
        final localLyrics = metadata['lyrics'] as String?;
        if (localLyrics != null && localLyrics.isNotEmpty) {
          _currentLyrics = LyricsService.instance.parseLrc(localLyrics);
          if (_currentLyrics.isNotEmpty) {
            _lyricsController.add(_currentLyrics);
            return;
          }
        }
      } catch (e) {
        debugPrint('Error reading local lyrics: $e');
      }
    }

    // 2. Fallback to online fetching
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
    _selfHealingSubscription?.cancel();
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
  Future<void> updateMediaItem(MediaItem mediaItem) async =>
      this.mediaItem.add(mediaItem);
  Future<void> updatePlaybackState(PlaybackState state) async =>
      playbackState.add(state);

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
