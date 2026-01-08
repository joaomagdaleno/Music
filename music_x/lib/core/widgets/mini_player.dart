import 'package:just_audio/just_audio.dart'; // media_kit removed
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:music_hub/features/player/services/playback_service.dart';
import 'package:music_hub/features/library/models/search_models.dart';
import 'package:rxdart/rxdart.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      return const _FluentMiniPlayer();
    }
    return const _MaterialMiniPlayer();
  }
}

class _FluentMiniPlayer extends StatefulWidget {
  const _FluentMiniPlayer();

  @override
  State<_FluentMiniPlayer> createState() => _FluentMiniPlayerState();
}

class _FluentMiniPlayerState extends State<_FluentMiniPlayer> {
  double _volume = 100.0;

  @override
  Widget build(BuildContext context) {
    final playback = PlaybackService.instance;
    final theme = fluent.FluentTheme.of(context);

    return StreamBuilder<bool>(
      stream: playback.player.playingStream,
      builder: (context, playingSnapshot) {
        final playing = playingSnapshot.data ?? false;

        return StreamBuilder<SearchResult?>(
          stream: playback.currentTrackStream.startWith(playback.currentTrack),
          builder: (context, trackSnapshot) {
            final track = trackSnapshot.data;
            if (track == null) return const SizedBox.shrink();

            return GestureDetector(
              onTap: () {
                // Navigation to PlayerScreen disabled for Pure Music
              },
              child: Container(
                height: 84,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border(
                    top: BorderSide(
                      color: theme.resources.dividerStrokeColorDefault,
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // LEFT: Track Info
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          if (track.thumbnail != null)
                            Hero(
                              tag: 'player_art',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  track.thumbnail!,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 56,
                                    height: 56,
                                    color: theme.menuColor,
                                    child: const Icon(
                                        fluent.FluentIcons.music_note),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  track.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.typography.caption?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          fluent.IconButton(
                            icon: Icon(
                              track.isVault
                                  ? fluent.FluentIcons.heart_fill
                                  : fluent.FluentIcons.heart,
                              color: track.isVault ? fluent.Colors.red : null,
                            ),
                            onPressed: () => playback.toggleFavorite(),
                          ),
                        ],
                      ),
                    ),

                    // CENTER: Controls & Progress
                    Expanded(
                      flex: 4,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Controls Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              StreamBuilder<bool>(
                                stream:
                                    playback.player.shuffleModeEnabledStream,
                                builder: (context, snapshot) {
                                  final isShuffle = snapshot.data ?? false;
                                  return fluent.IconButton(
                                    icon: Icon(
                                      Icons.shuffle,
                                      color:
                                          isShuffle ? theme.accentColor : null,
                                    ),
                                    onPressed: () => playback.toggleShuffle(),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              fluent.IconButton(
                                icon: const Icon(fluent.FluentIcons.previous),
                                onPressed: () => playback.previous(),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: theme.accentColor,
                                  shape: BoxShape.circle,
                                ),
                                child: fluent.IconButton(
                                  icon: Icon(
                                    playing
                                        ? fluent.FluentIcons.pause
                                        : fluent.FluentIcons.play,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  onPressed: () => playing
                                      ? playback.pause()
                                      : playback.resume(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              fluent.IconButton(
                                icon: const Icon(fluent.FluentIcons.next),
                                onPressed: () => playback.next(),
                              ),
                              const SizedBox(width: 8),
                              StreamBuilder<LoopMode>(
                                stream: playback.player.loopModeStream,
                                builder: (context, snapshot) {
                                  final mode = snapshot.data ?? LoopMode.off;
                                  IconData icon;
                                  Color? color;
                                  if (mode == LoopMode.one) {
                                    icon = Icons.repeat_one;
                                    color = theme.accentColor;
                                  } else if (mode == LoopMode.all) {
                                    icon = Icons.repeat;
                                    color = theme.accentColor;
                                  } else {
                                    icon = Icons.repeat;
                                    color = null;
                                  }
                                  return fluent.IconButton(
                                    icon: Icon(icon, color: color),
                                    onPressed: () => playback.toggleRepeat(),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Progress Bar
                          StreamBuilder<Duration>(
                            stream: playback.player.positionStream,
                            builder: (context, posSnapshot) {
                              final position =
                                  posSnapshot.data ?? Duration.zero;
                              final duration =
                                  playback.player.duration ?? Duration.zero;
                              final max = duration.inMilliseconds.toDouble();
                              final value = position.inMilliseconds
                                  .toDouble()
                                  .clamp(0.0, max > 0 ? max : 1.0);

                              return RepaintBoundary(
                                // ⚡ Bolt: Isolate progress bar
                                child: SizedBox(
                                  width: 400,
                                  child: Row(
                                    children: [
                                      Text(
                                        _formatDuration(position),
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: theme
                                                .typography.caption?.color),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: fluent.Slider(
                                          value: value,
                                          max: max > 0 ? max : 1.0,
                                          onChanged: (val) {
                                            playback.seek(Duration(
                                                milliseconds: val.toInt()));
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatDuration(duration),
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: theme
                                                .typography.caption?.color),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // RIGHT: Volume & Extras
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          fluent.IconButton(
                            icon: const Icon(fluent.FluentIcons.playlist_music),
                            onPressed: () {
                              // Show Queue
                            },
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 100,
                            child: Row(
                              children: [
                                const Icon(fluent.FluentIcons.volume2,
                                    size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: fluent.Slider(
                                    value: _volume,
                                    max: 100,
                                    onChanged: (v) {
                                      setState(() => _volume = v);
                                      playback.player.setVolume(v);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          fluent.IconButton(
                            icon: const fluent.Icon(
                                fluent.FluentIcons.chrome_close),
                            onPressed: () => playback.stop(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _MaterialMiniPlayer extends StatelessWidget {
  const _MaterialMiniPlayer();

  @override
  Widget build(BuildContext context) {
    final playback = PlaybackService.instance;

    return StreamBuilder<bool>(
      stream: playback.player.playingStream,
      builder: (context, playingSnapshot) {
        final playing = playingSnapshot.data ?? false;
        return StreamBuilder<SearchResult?>(
          stream: playback.currentTrackStream.startWith(playback.currentTrack),
          builder: (context, trackSnapshot) {
            final track = trackSnapshot.data;
            if (track == null) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.all(8),
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () {
                  // Navigation to PlayerScreen disabled for Pure Music
                },
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: [
                    // Progress Indicator (Thin line at top)
                    RepaintBoundary(
                      // ⚡ Bolt: Isolate progress bar
                      child: StreamBuilder<Duration>(
                          stream: playback.player.positionStream,
                          builder: (context, posSnapshot) {
                            final position = posSnapshot.data ?? Duration.zero;
                            final duration =
                                playback.player.duration ?? Duration.zero;
                            final progress = duration.inMilliseconds > 0
                                ? position.inMilliseconds /
                                    duration.inMilliseconds
                                : 0.0;
                            return LinearProgressIndicator(
                              value: progress,
                              minHeight: 2,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation(
                                Theme.of(context).colorScheme.primary,
                              ),
                            );
                          }),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            // Art
                            if (track.thumbnail != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  track.thumbnail!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.music_note),
                                ),
                              ),
                            const SizedBox(width: 12),
                            // Info
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    track.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Controls
                            // Controls
                            IconButton(
                              icon: Icon(track.isVault
                                  ? Icons.favorite
                                  : Icons.favorite_border),
                              color: track.isVault ? Colors.red : null,
                              onPressed: () => playback.toggleFavorite(),
                            ),
                            const SizedBox(width: 8),
                            // Shuffle
                            StreamBuilder<bool>(
                              stream: playback.player.shuffleModeEnabledStream,
                              builder: (context, snapshot) {
                                final isShuffle = snapshot.data ?? false;
                                return IconButton(
                                  icon: const Icon(Icons.shuffle),
                                  color: isShuffle
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                  onPressed: () => playback.toggleShuffle(),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_previous),
                              onPressed: () => playback.previous(),
                            ),
                            IconButton(
                              icon: Icon(playing
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled),
                              iconSize: 40,
                              color: Theme.of(context).colorScheme.primary,
                              onPressed: () => playing
                                  ? playback.pause()
                                  : playback.resume(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_next),
                              onPressed: () => playback.next(),
                            ),
                            // Repeat
                            StreamBuilder<LoopMode>(
                              stream: playback.player.loopModeStream,
                              builder: (context, snapshot) {
                                final mode = snapshot.data ?? LoopMode.off;
                                IconData icon;
                                Color? color;
                                if (mode == LoopMode.one) {
                                  icon = Icons.repeat_one;
                                  color = Theme.of(context).colorScheme.primary;
                                } else if (mode == LoopMode.all) {
                                  icon = Icons.repeat;
                                  color = Theme.of(context).colorScheme.primary;
                                } else {
                                  icon = Icons.repeat;
                                  color = null;
                                }
                                return IconButton(
                                  icon: Icon(icon),
                                  color: color,
                                  onPressed: () => playback.toggleRepeat(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
