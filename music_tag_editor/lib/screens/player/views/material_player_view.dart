import 'package:flutter/material.dart';
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
              onPressed: () => showDialog(
                  context: context, builder: (_) => const DuoChatDialog()),
              tooltip: 'Chat Duo',
            ),
          IconButton(
              icon: const Icon(Icons.timer_outlined),
              onPressed: () => onShowSleepTimer(context),
              tooltip: 'Sleep Timer'),
          IconButton(
              icon: const Icon(Icons.queue_music),
              onPressed: () => onShowQueue(context),
              tooltip: 'Fila Compartilhada'),
          IconButton(
              icon: const Icon(Icons.people_alt),
              onPressed: () => onShowDuoMatching(context),
              tooltip: 'Modo Duo'),
          IconButton(
              icon: const Icon(Icons.cast),
              onPressed: () => onShowCast(context),
              tooltip: 'Transmitir (DLNA)'),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: StreamBuilder<bool>(
        stream: playback.player.stream.playing,
        builder: (context, snapshot) {
          final track = playback.currentTrack;
          if (track == null) {
            return const Center(child: Text('Nenhuma música tocando'));
          }

          final playing = snapshot.data ?? false;

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

  Widget _buildWideLayout(BuildContext context, dynamic track, bool playing,
          PlaybackService playback) =>
      Row(
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(track.thumbnail!,
                            width: 300,
                            height: 300,
                            fit: BoxFit.cover,
                            cacheWidth: 600),
                      ),
                    ),
                  ),
                VisualizerWidget(
                    isPlaying: playing,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(track.title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                Text(track.artist,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            flex: 6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                const RepaintBoundary(
                    child: ProgressBar()), // ⚡ Bolt: Isolate frequent updates
                const SizedBox(height: 32),
                _buildControlButtons(context, playing, playback, track),
                const SizedBox(height: 32),
                const Expanded(
                    child: RepaintBoundary(
                        child:
                            LyricsView())), // ⚡ Bolt: Isolate lyrics repaints
              ],
            ),
          ),
        ],
      );

  Widget _buildMobileLayout(BuildContext context, dynamic track, bool playing,
          PlaybackService playback) =>
      Center(
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
                    child: Image.network(track.thumbnail!,
                        width: 250,
                        height: 250,
                        fit: BoxFit.cover,
                        cacheWidth: 500),
                  ),
                ),
              ),
            Text(track.title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            Text(track.artist,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.grey)),
            const SizedBox(height: 32),
            const ProgressBar(),
            const SizedBox(height: 16),
            _buildControlButtons(context, playing, playback, track),
            const Expanded(child: LyricsView()),
          ],
        ),
      );

  Widget _buildControlButtons(BuildContext context, bool playing,
          PlaybackService playback, dynamic track,
          {bool showKaraoke = false}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
              iconSize: 48,
              icon: const Icon(Icons.skip_previous),
              onPressed: () {}),
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
          IconButton(
              iconSize: 48,
              icon: const Icon(Icons.skip_next),
              onPressed: () {}),
          const SizedBox(width: 16),
          IconButton(
            iconSize: 32,
            icon: Icon(track.isVault ? Icons.favorite : Icons.favorite_border),
            color: track.isVault ? Colors.red : null,
            onPressed: () => playback.toggleFavorite(),
          ),
          if (showKaraoke) ...[
            const SizedBox(width: 16),
            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.mic_external_on),
              tooltip: 'Modo Karaoke',
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => KaraokeScreen(track: {
                              'id': track.id,
                              'title': track.title,
                              'artist': track.artist
                            })));
              },
            ),
          ],
        ],
      );
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    final player = PlaybackService.instance.player;
    return StreamBuilder<Duration>(
      stream: player.stream.position,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = player.state.duration;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              Slider(
                value: position.inMilliseconds.toDouble(),
                max: duration.inMilliseconds
                    .toDouble()
                    .clamp(position.inMilliseconds.toDouble(), double.infinity),
                onChanged: (val) => PlaybackService.instance
                    .seek(Duration(milliseconds: val.toInt())),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(position)),
                  Text(_formatDuration(duration))
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

class LyricsView extends StatelessWidget {
  const LyricsView({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<List<LyricLine>>(
        stream: PlaybackService.instance.lyricsStream,
        builder: (context, snapshot) {
          final lyrics = snapshot.data ?? [];
          if (lyrics.isEmpty) {
            return const Center(
              child: Text(
                'Letras não encontradas',
                style:
                    TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            );
          }

          return StreamBuilder<Duration>(
            stream: PlaybackService.instance.player.stream.position,
            builder: (context, posSnapshot) {
              final position = posSnapshot.data ?? Duration.zero;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 20),
                itemCount: lyrics.length,
                itemBuilder: (context, index) {
                  final line = lyrics[index];
                  final isCurrent = index < lyrics.length - 1
                      ? position >= line.time &&
                          position < lyrics[index + 1].time
                      : position >= line.time;

                  return AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: isCurrent ? 24 : 18,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 32),
                      child: Text(
                        line.text,
                        textAlign: TextAlign.center,
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
