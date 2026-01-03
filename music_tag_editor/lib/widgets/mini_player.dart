import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_tag_editor/screens/player/player_screen.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/download_service.dart';
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

class _FluentMiniPlayer extends StatelessWidget {
  const _FluentMiniPlayer();

  @override
  Widget build(BuildContext context) {
    final playback = PlaybackService.instance;

    return StreamBuilder<Map<String, dynamic>>(
      stream: Rx.combineLatest3(
        playback.player.playerStateStream,
        playback.currentTrackStream.startWith(playback.currentTrack),
        playback.player.positionStream,
        (state, track, position) => {
          'state': state,
          'track': track,
          'position': position,
        },
      ),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final track = data?['track'] as SearchResult?;
        final state = data?['state'] as PlayerState?;
        final position = data?['position'] as Duration? ?? Duration.zero;
        final duration = playback.player.duration ?? Duration.zero;
        
        if (track == null) {
          return const SizedBox.shrink();
        }

        final playing = state?.playing ?? false;
        final progress = duration.inMilliseconds > 0 
            ? position.inMilliseconds / duration.inMilliseconds 
            : 0.0;

        return fluent.HoverButton(
          onPressed: () {
            Navigator.push(
              context,
              fluent.FluentPageRoute(builder: (context) => const PlayerScreen()),
            );
          },
          builder: (context, states) {
            return Container(
              height: 72,
              decoration: BoxDecoration(
                color: fluent.FluentTheme.of(context).cardColor,
                border: Border(
                  top: BorderSide(
                    color: fluent.FluentTheme.of(context).resources.dividerStrokeColorDefault,
                    width: 1,
                  ),
                ),
              ),
              child: Stack(
                children: [
                   // Progress Bar at the top
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: 2,
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          fluent.FluentTheme.of(context).accentColor,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        if (track.thumbnail != null)
                          Hero(
                            tag: 'player_art',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: track.thumbnail != null && (track.thumbnail!.startsWith('http') || track.thumbnail!.startsWith('https'))
                              ? Image.network(track.thumbnail!, width: 48, height: 48, fit: BoxFit.cover)
                              : track.thumbnail != null
                                  ? Image.file(File(track.thumbnail!), width: 48, height: 48, fit: BoxFit.cover)
                                  : const Icon(fluent.FluentIcons.music_note),
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
                                  color: fluent.FluentTheme.of(context).typography.caption?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        fluent.IconButton(
                          icon: Icon(playing ? fluent.FluentIcons.pause : fluent.FluentIcons.play),
                          onPressed: () => playing ? playback.pause() : playback.resume(),
                        ),
                        const SizedBox(width: 8),
                        fluent.IconButton(
                          icon: const Icon(fluent.FluentIcons.clear),
                          onPressed: () => playback.stop(),
                        ),
                      ],
                    ),
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

    return StreamBuilder<Map<String, dynamic>>(
      stream: Rx.combineLatest3(
        playback.player.playerStateStream,
        playback.currentTrackStream.startWith(playback.currentTrack),
        playback.player.positionStream,
        (state, track, position) => {
          'state': state,
          'track': track,
          'position': position,
        },
      ),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final track = data?['track'] as SearchResult?;
        final state = data?['state'] as PlayerState?;
        final position = data?['position'] as Duration? ?? Duration.zero;
        final duration = playback.player.duration ?? Duration.zero;
        
        if (track == null) {
          return const SizedBox.shrink();
        }

        final playing = state?.playing ?? false;
        final progress = duration.inMilliseconds > 0 
            ? position.inMilliseconds / duration.inMilliseconds 
            : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PlayerScreen()),
                    );
                  },
                  child: Stack(
                children: [
                   // Progress Bar at the bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: 2,
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        if (track.thumbnail != null)
                          Hero(
                            tag: 'player_art',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: track.thumbnail != null && (track.thumbnail!.startsWith('http') || track.thumbnail!.startsWith('https'))
                                ? Image.network(track.thumbnail!, width: 44, height: 44, fit: BoxFit.cover)
                                : track.thumbnail != null
                                    ? Image.file(File(track.thumbnail!), width: 44, height: 44, fit: BoxFit.cover)
                                    : const Icon(Icons.music_note),
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
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                          onPressed: () => playing ? playback.pause() : playback.resume(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => playback.stop(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
