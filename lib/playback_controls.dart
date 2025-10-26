import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'audio_player_service.dart';
import 'main.dart'; // To get MusicTrack
import 'lyrics_dialog.dart'; // Import the lyrics dialog

class PlaybackControls extends StatefulWidget {
  const PlaybackControls({super.key});

  @override
  State<PlaybackControls> createState() => _PlaybackControlsState();
}

class _PlaybackControlsState extends State<PlaybackControls> {
  final AudioPlayerService _audioPlayerService = AudioPlayerService();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
           // Progress Bar
          StreamBuilder<Duration>(
            stream: _audioPlayerService.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              return StreamBuilder<Duration?>(
                stream: _audioPlayerService.durationStream,
                builder: (context, snapshot) {
                  final duration = snapshot.data ?? Duration.zero;
                  return Slider(
                    value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
                    min: 0.0,
                    max: duration.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      _audioPlayerService.seek(Duration(milliseconds: value.toInt()));
                    },
                  );
                },
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Album Art and Track Info
              StreamBuilder<SequenceState?>(
                stream: _audioPlayerService.sequenceStateStream,
                builder: (context, snapshot) {
                  final state = snapshot.data;
                  if (state?.sequence.isEmpty ?? true) return const SizedBox(width: 150, height: 50);
                  final track = state!.currentSource!.tag as MusicTrack;
                  return Row(
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: track.albumArt != null
                            ? Image.memory(track.albumArt!)
                            : const Icon(Icons.music_note),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(track.title, style: Theme.of(context).textTheme.bodyLarge, overflow: TextOverflow.ellipsis),
                            Text(track.artist, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Playback Buttons
              StreamBuilder<SequenceState?>(
                stream: _audioPlayerService.sequenceStateStream,
                builder: (context, snapshot) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        onPressed: snapshot.data?.hasPrevious ?? false ? _audioPlayerService.seekToPrevious : null
                      ),
                      StreamBuilder<PlayerState>(
                        stream: _audioPlayerService.playerStateStream,
                        builder: (context, snapshot) {
                          final playerState = snapshot.data;
                          final processingState = playerState?.processingState;
                          final playing = playerState?.playing;
                          if (playing != true) {
                            return IconButton(
                              icon: const Icon(Icons.play_arrow),
                              iconSize: 48.0,
                              onPressed: _audioPlayerService.play,
                            );
                          } else if (processingState != ProcessingState.completed) {
                            return IconButton(
                              icon: const Icon(Icons.pause),
                              iconSize: 48.0,
                              onPressed: _audioPlayerService.pause,
                            );
                          } else {
                            return IconButton(
                              icon: const Icon(Icons.replay),
                              iconSize: 48.0,
                              onPressed: () => _audioPlayerService.seek(Duration.zero),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        onPressed: snapshot.data?.hasNext ?? false ? _audioPlayerService.seekToNext : null
                      ),
                    ],
                  );
                }
              ),
              // Volume and Repeat
              Row(
                children: [
                  // Lyrics Button
                  StreamBuilder<SequenceState?>(
                    stream: _audioPlayerService.sequenceStateStream,
                    builder: (context, snapshot) {
                      final track = snapshot.data?.currentSource?.tag as MusicTrack?;
                      final hasLyrics = track?.lyrics != null && track!.lyrics!.isNotEmpty;
                      return IconButton(
                        icon: const Icon(Icons.mic_external_on),
                        onPressed: hasLyrics ? () {
                          showDialog(
                            context: context,
                            builder: (context) => LyricsDialog(lyrics: track.lyrics!),
                          );
                        } : null,
                      );
                    },
                  ),
                  const Icon(Icons.volume_up),
                  SizedBox(
                    width: 100,
                    child: StreamBuilder<double>(
                      stream: _audioPlayerService.volumeStream,
                      builder: (context, snapshot) {
                        return Slider(
                          value: snapshot.data ?? 1.0,
                          onChanged: _audioPlayerService.setVolume,
                        );
                      },
                    ),
                  ),
                  StreamBuilder<LoopMode>(
                    stream: _audioPlayerService.loopModeStream,
                    builder: (context, snapshot) {
                      final loopMode = snapshot.data ?? LoopMode.off;
                      const icons = [ Icon(Icons.repeat), Icon(Icons.repeat_one) ];
                      const cycleModes = [ LoopMode.off, LoopMode.all, LoopMode.one ];
                      final index = cycleModes.indexOf(loopMode);
                      return IconButton(
                        icon: loopMode == LoopMode.off ? icons[0] : icons[1],
                        color: loopMode != LoopMode.off ? Theme.of(context).colorScheme.primary : null,
                        onPressed: () {
                          _audioPlayerService.setLoopMode(cycleModes[(index + 1) % cycleModes.length]);
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
