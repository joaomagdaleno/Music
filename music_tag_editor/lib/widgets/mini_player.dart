import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_tag_editor/screens/player/player_screen.dart';
import 'package:music_tag_editor/services/playback_service.dart';

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

class _FluentMiniPlayer extends StatelessWidget {
  const _FluentMiniPlayer();

  @override
  Widget build(BuildContext context) {
    final playback = PlaybackService.instance;

    return StreamBuilder<PlayerState>(
      stream: playback.player.playerStateStream,
      builder: (context, snapshot) {
        final track = playback.currentTrack;
        if (track == null ||
            snapshot.data?.processingState == ProcessingState.idle) {
          return const SizedBox.shrink();
        }

        final playing = snapshot.data?.playing ?? false;

        return fluent.HoverButton(
          onPressed: () {
            Navigator.push(
              context,
              fluent.FluentPageRoute(builder: (context) => const PlayerScreen()),
            );
          },
          builder: (context, states) {
            return Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: fluent.FluentTheme.of(context).cardColor,
                border: Border(
                  top: BorderSide(
                    color: fluent.FluentTheme.of(context).resources.dividerStrokeColorDefault,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (track.thumbnail != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        track.thumbnail!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          track.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: fluent.FluentTheme.of(context)
                                .typography.caption
                                ?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  fluent.IconButton(
                    icon: Icon(playing ? fluent.FluentIcons.pause : fluent.FluentIcons.play),
                    onPressed: () {
                      if (playing) {
                        playback.pause();
                      } else {
                        playback.resume();
                      }
                    },
                  ),
                  fluent.IconButton(
                    icon: const Icon(fluent.FluentIcons.clear),
                    onPressed: () => playback.stop(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MaterialMiniPlayer extends StatelessWidget {
  const _MaterialMiniPlayer();

  @override
  Widget build(BuildContext context) {
    final playback = PlaybackService.instance;

    return StreamBuilder<PlayerState>(
      stream: playback.player.playerStateStream,
      builder: (context, snapshot) {
        final track = playback.currentTrack;
        if (track == null ||
            snapshot.data?.processingState == ProcessingState.idle) {
          return const SizedBox.shrink();
        }

        final playing = snapshot.data?.playing ?? false;

        return Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PlayerScreen()),
              );
            },
            child: Row(
              children: [
                if (track.thumbnail != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      track.thumbnail!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    if (playing) {
                      playback.pause();
                    } else {
                      playback.resume();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => playback.stop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
