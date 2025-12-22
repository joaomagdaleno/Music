import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'playback_service.dart';
import 'duo_matching_dialog.dart';
import 'local_duo_service.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playback = PlaybackService.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tocando Agora'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const DuoMatchingDialog(),
              );
            },
            tooltip: 'Modo Duo',
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: StreamBuilder<PlayerState>(
        stream: playback.player.playerStateStream,
        builder: (context, snapshot) {
          final track = playback.currentTrack;
          if (track == null) {
            return const Center(child: Text('Nenhuma música tocando'));
          }

          final playing = snapshot.data?.playing ?? false;

          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (track.thumbnail != null)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          track.thumbnail!,
                          width: 300,
                          height: 300,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  track.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Text(
                  track.artist,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                _ProgressBar(player: playback.player),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 48,
                      icon: const Icon(Icons.skip_previous),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 16),
                    CircleAvatar(
                      radius: 36,
                      child: IconButton(
                        iconSize: 48,
                        icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                        onPressed: () {
                          if (playing) {
                            playback.pause();
                          } else {
                            playback.resume();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      iconSize: 48,
                      icon: const Icon(Icons.skip_next),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final AudioPlayer player;
  const _ProgressBar({required this.player});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = player.duration ?? Duration.zero;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              Slider(
                value: position.inMilliseconds.toDouble(),
                max: duration.inMilliseconds
                    .toDouble()
                    .clamp(position.inMilliseconds.toDouble(), double.infinity),
                onChanged: (val) {
                  PlaybackService.instance
                      .seek(Duration(milliseconds: val.toInt()));
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(position)),
                  Text(_formatDuration(duration)),
                ],
              ),
            ],
          ),
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
