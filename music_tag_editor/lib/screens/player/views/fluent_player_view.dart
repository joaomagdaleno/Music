import 'package:fluent_ui/fluent_ui.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/lyrics_service.dart';

class FluentPlayerView extends StatelessWidget {
  final void Function(BuildContext) onShowSleepTimer;
  final void Function(BuildContext) onShowQueue;
  final void Function(BuildContext) onShowDuoMatching;
  final void Function(BuildContext) onShowCast;

  const FluentPlayerView({
    super.key,
    required this.onShowSleepTimer,
    required this.onShowQueue,
    required this.onShowDuoMatching,
    required this.onShowCast,
  });

  @override
  Widget build(BuildContext context) {
    final playback = PlaybackService.instance;

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Tocando Agora'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(icon: const Icon(FluentIcons.timer), label: const Text('Timer'), onPressed: () => onShowSleepTimer(context)),
            CommandBarButton(icon: const Icon(FluentIcons.playlist_music), label: const Text('Fila'), onPressed: () => onShowQueue(context)),
            CommandBarButton(icon: const Icon(FluentIcons.people), label: const Text('Duo'), onPressed: () => onShowDuoMatching(context)),
            CommandBarButton(icon: const Icon(FluentIcons.air_tickets), label: const Text('Cast'), onPressed: () => onShowCast(context)),
          ],
        ),
      ),
      content: StreamBuilder<PlayerState>(
        stream: playback.player.playerStateStream,
        builder: (context, snapshot) {
          final track = playback.currentTrack;
          if (track == null) return const Center(child: Text('Nenhuma música tocando'));

          final playing = snapshot.data?.playing ?? false;

          return Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Album Art
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (track.thumbnail != null)
                        Card(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(track.thumbnail!, width: 300, height: 300, fit: BoxFit.cover),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text(track.title, style: FluentTheme.of(context).typography.title),
                      Text(track.artist, style: FluentTheme.of(context).typography.body),
                    ],
                  ),
                ),
                // Controls & Lyrics
                Expanded(
                  flex: 6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FluentProgressBar(player: playback.player),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(icon: const Icon(FluentIcons.previous, size: 32), onPressed: () {}),
                          const SizedBox(width: 24),
                          FilledButton(
                            onPressed: () => playing ? playback.pause() : playback.resume(),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Icon(playing ? FluentIcons.pause : FluentIcons.play, size: 32),
                            ),
                          ),
                          const SizedBox(width: 24),
                          IconButton(icon: const Icon(FluentIcons.next, size: 32), onPressed: () {}),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Expanded(child: FluentLyricsView()),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class FluentProgressBar extends StatelessWidget {
  final AudioPlayer player;
  const FluentProgressBar({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = player.duration ?? Duration.zero;
        final maxVal = duration.inMilliseconds.toDouble().clamp(1.0, double.infinity);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              Slider(
                value: position.inMilliseconds.toDouble().clamp(0, maxVal),
                max: maxVal,
                onChanged: (val) => PlaybackService.instance.seek(Duration(milliseconds: val.toInt())),
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

  String _formatDuration(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

class FluentLyricsView extends StatelessWidget {
  const FluentLyricsView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LyricLine>>(
      stream: PlaybackService.instance.lyricsStream,
      builder: (context, snapshot) {
        final lyrics = snapshot.data ?? [];
        if (lyrics.isEmpty) {
          return Center(child: Text('Buscando letras...', style: FluentTheme.of(context).typography.caption));
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
                    style: isCurrent ? FluentTheme.of(context).typography.bodyStrong : FluentTheme.of(context).typography.body,
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
