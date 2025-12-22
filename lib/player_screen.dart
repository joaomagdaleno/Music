import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'playback_service.dart';
import 'duo_matching_dialog.dart';
import 'local_duo_service.dart';
import 'duo_chat_dialog.dart';
import 'visualizer_widget.dart';
import 'lyrics_service.dart';
import 'karaoke_view.dart';
import 'cast_dialog.dart';

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
          StreamBuilder<Duration?>(
            stream: PlaybackService.instance.sleepTimerStream,
            builder: (context, snapshot) {
              final timeLeft = snapshot.data;
              if (timeLeft == null) return const SizedBox.shrink();
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    '${timeLeft.inMinutes}:${(timeLeft.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
              );
            },
          ),
          if (LocalDuoService.instance.role != DuoRole.none)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const DuoChatDialog(),
                );
              },
              tooltip: 'Chat Duo',
            ),
          IconButton(
            icon: const Icon(Icons.timer_outlined),
            onPressed: () => _showSleepTimerDialog(context),
            tooltip: 'Sleep Timer',
          ),
          IconButton(
            icon: const Icon(Icons.queue_music),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => const QueueSheet(),
              );
            },
            tooltip: 'Fila Compartilhada',
          ),
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
          IconButton(
            icon: const Icon(Icons.cast),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const CastDialog(),
              );
            },
            tooltip: 'Transmitir (DLNA)',
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
                const SizedBox(height: 8),
                VisualizerWidget(
                  isPlaying: playing,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
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
                    const SizedBox(width: 16),
                    IconButton(
                      iconSize: 32,
                      icon: const Icon(Icons.mic_external_on),
                      tooltip: 'Modo Karaoke',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => KaraokeView(track: {
                              'id': track.id,
                              'title': track.title,
                              'artist': track.artist,
                            }),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Flexible(child: LyricsView()),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSleepTimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Temporizador (Sleep Timer)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Desligar'),
              onTap: () {
                PlaybackService.instance.cancelSleepTimer();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('15 minutos'),
              onTap: () {
                PlaybackService.instance
                    .setSleepTimer(const Duration(minutes: 15));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('30 minutos'),
              onTap: () {
                PlaybackService.instance
                    .setSleepTimer(const Duration(minutes: 30));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('60 minutos'),
              onTap: () {
                PlaybackService.instance
                    .setSleepTimer(const Duration(minutes: 60));
                Navigator.pop(context);
              },
            ),
          ],
        ),
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

class QueueSheet extends StatelessWidget {
  const QueueSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final playback = PlaybackService.instance;
    final queue = playback.queue;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Fila Compartilhada',
              style: Theme.of(context).textTheme.titleLarge),
          const Divider(),
          if (queue.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                  'A fila está vazia. Adicione músicas da biblioteca do seu amigo!'),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: queue.length,
                itemBuilder: (context, index) {
                  final track = queue[index];
                  return ListTile(
                    leading: const Icon(Icons.music_note),
                    title: Text(track.title),
                    subtitle: Text(track.artist),
                    trailing: const Icon(Icons.drag_handle),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class LyricsView extends StatelessWidget {
  const LyricsView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LyricLine>>(
      stream: PlaybackService.instance.lyricsStream,
      builder: (context, snapshot) {
        final lyrics = snapshot.data ?? [];
        if (lyrics.isEmpty) {
          return const Center(
            child: Text(
              'Buscando letras...',
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          );
        }

        return StreamBuilder<Duration>(
          stream: PlaybackService.instance.player.positionStream,
          builder: (context, posSnapshot) {
            final position = posSnapshot.data ?? Duration.zero;
            return ListView.builder(
              itemCount: lyrics.length,
              itemBuilder: (context, index) {
                final line = lyrics[index];
                final isCurrent = index < lyrics.length - 1
                    ? position >= line.time && position < lyrics[index + 1].time
                    : position >= line.time;

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24),
                  child: Text(
                    line.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCurrent ? 18 : 16,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
