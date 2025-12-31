import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/local_duo_service.dart';
import 'package:music_tag_editor/widgets/duo_chat_dialog.dart';
import 'package:music_tag_editor/widgets/visualizer_widget.dart';
import 'package:music_tag_editor/services/lyrics_service.dart';
import 'package:music_tag_editor/screens/disco/karaoke_screen.dart';

class MaterialPlayerView extends StatelessWidget {
  final void Function(BuildContext) onShowSleepTimer;
  final void Function(BuildContext) onShowQueue;
  final void Function(BuildContext) onShowDuoMatching;
  final void Function(BuildContext) onShowCast;

  const MaterialPlayerView({
    super.key,
    required this.onShowSleepTimer,
    required this.onShowQueue,
    required this.onShowDuoMatching,
    required this.onShowCast,
  });

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
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
              );
            },
          ),
          if (LocalDuoService.instance.role != DuoRole.none)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: () => showDialog(context: context, builder: (_) => const DuoChatDialog()),
              tooltip: 'Chat Duo',
            ),
          IconButton(icon: const Icon(Icons.timer_outlined), onPressed: () => onShowSleepTimer(context), tooltip: 'Sleep Timer'),
          IconButton(icon: const Icon(Icons.queue_music), onPressed: () => onShowQueue(context), tooltip: 'Fila Compartilhada'),
          IconButton(icon: const Icon(Icons.people_alt), onPressed: () => onShowDuoMatching(context), tooltip: 'Modo Duo'),
          IconButton(icon: const Icon(Icons.cast), onPressed: () => onShowCast(context), tooltip: 'Transmitir (DLNA)'),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: StreamBuilder<PlayerState>(
        stream: playback.player.playerStateStream,
        builder: (context, snapshot) {
          final track = playback.currentTrack;
          if (track == null) return const Center(child: Text('Nenhuma música tocando'));

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 800) {
                  return _buildWideLayout(context, track, playing, playback);
                }
                return _buildMobileLayout(context, track, playing, playback);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildWideLayout(BuildContext context, dynamic track, bool playing, PlaybackService playback) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (track.thumbnail != null)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(track.thumbnail!, width: 300, height: 300, fit: BoxFit.cover),
                    ),
                  ),
                ),
              VisualizerWidget(isPlaying: playing, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(track.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              Text(track.artist, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey)),
            ],
          ),
        ),
        Expanded(
          flex: 6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              ProgressBar(player: playback.player),
              const SizedBox(height: 32),
              _buildControlButtons(context, playing, playback, track),
              const SizedBox(height: 32),
              const Expanded(child: LyricsView()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, dynamic track, bool playing, PlaybackService playback) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (track.thumbnail != null)
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(track.thumbnail!, width: 300, height: 300, fit: BoxFit.cover),
              ),
            ),
          ),
        const SizedBox(height: 8),
        VisualizerWidget(isPlaying: playing, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(track.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        Text(track.artist, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
        const SizedBox(height: 32),
        ProgressBar(player: playback.player),
        const SizedBox(height: 32),
        _buildControlButtons(context, playing, playback, track, showKaraoke: true),
        const SizedBox(height: 16),
        const Flexible(child: LyricsView()),
      ],
    );
  }

  Widget _buildControlButtons(BuildContext context, bool playing, PlaybackService playback, dynamic track, {bool showKaraoke = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(iconSize: 48, icon: const Icon(Icons.skip_previous), onPressed: () {}),
        const SizedBox(width: 16),
        CircleAvatar(
          radius: 36,
          child: IconButton(
            iconSize: 48,
            icon: Icon(playing ? Icons.pause : Icons.play_arrow),
            onPressed: () => playing ? playback.pause() : playback.resume(),
          ),
        ),
        const SizedBox(width: 16),
        IconButton(iconSize: 48, icon: const Icon(Icons.skip_next), onPressed: () {}),
        if (showKaraoke) ...[
          const SizedBox(width: 16),
          IconButton(
            iconSize: 32,
            icon: const Icon(Icons.mic_external_on),
            tooltip: 'Modo Karaoke',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => KaraokeScreen(track: {'id': track.id, 'title': track.title, 'artist': track.artist})));
            },
          ),
        ],
      ],
    );
  }
}

class ProgressBar extends StatelessWidget {
  final AudioPlayer player;
  const ProgressBar({super.key, required this.player});

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
                max: duration.inMilliseconds.toDouble().clamp(position.inMilliseconds.toDouble(), double.infinity),
                onChanged: (val) => PlaybackService.instance.seek(Duration(milliseconds: val.toInt())),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text(_formatDuration(position)), Text(_formatDuration(duration))],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

class QueueSheet extends StatelessWidget {
  const QueueSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = PlaybackService.instance.queue;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Fila Compartilhada', style: Theme.of(context).textTheme.titleLarge),
          const Divider(),
          if (queue.isEmpty)
            const Padding(padding: EdgeInsets.all(32.0), child: Text('A fila está vazia. Adicione músicas da biblioteca do seu amigo!'))
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: queue.length,
                itemBuilder: (context, index) {
                  final track = queue[index];
                  return ListTile(leading: const Icon(Icons.music_note), title: Text(track.title), subtitle: Text(track.artist), trailing: const Icon(Icons.drag_handle));
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
          return const Center(child: Text('Buscando letras...', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)));
        }

        return StreamBuilder<Duration>(
          stream: PlaybackService.instance.player.positionStream,
          builder: (context, posSnapshot) {
            final position = posSnapshot.data ?? Duration.zero;
            return ListView.builder(
              itemCount: lyrics.length,
              itemBuilder: (context, index) {
                final line = lyrics[index];
                final isCurrent = index < lyrics.length - 1 ? position >= line.time && position < lyrics[index + 1].time : position >= line.time;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24),
                  child: Text(
                    line.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCurrent ? 18 : 16,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? Theme.of(context).colorScheme.primary : Colors.grey,
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
