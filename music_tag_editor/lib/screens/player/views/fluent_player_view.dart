import 'package:fluent_ui/fluent_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/lyrics_service.dart';
import 'package:music_tag_editor/models/search_models.dart';
import 'package:music_tag_editor/widgets/visualizer_widget.dart';

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
        leading: Navigator.canPop(context)
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: IconButton(
                  icon: const Icon(FluentIcons.back),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            : null,
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
                icon: const Icon(FluentIcons.timer),
                label: const Text('Timer'),
                onPressed: () => onShowSleepTimer(context)),
            CommandBarButton(
                icon: const Icon(FluentIcons.playlist_music),
                label: const Text('Fila'),
                onPressed: () => onShowQueue(context)),
            CommandBarButton(
                icon: const Icon(FluentIcons.people),
                label: const Text('Duo'),
                onPressed: () => onShowDuoMatching(context)),
            CommandBarButton(
                icon: const Icon(FluentIcons.air_tickets),
                label: const Text('Cast'),
                onPressed: () => onShowCast(context)),
          ],
        ),
      ),
      content: StreamBuilder<SearchResult?>(
        stream: playback.currentTrackStream,
        builder: (context, snapshot) {
          final track = snapshot.data;
          if (track == null) {
            return const Center(child: Text('Nenhuma música tocando'));
          }

          return Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Album Art and Title
                    Expanded(
                      flex: 4,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (track.thumbnail != null)
                            Container(
                              width: 300,
                              height: 300,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  track.thumbnail!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          const SizedBox(height: 32),
                          StreamBuilder<bool>(
                            stream: playback.player.stream.playing,
                            builder: (context, playingSnapshot) {
                              final playing = playingSnapshot.data ?? false;
                              return VisualizerWidget(
                                isPlaying: playing,
                                color: FluentTheme.of(context).accentColor,
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          Text(
                            track.title,
                            style: FluentTheme.of(context).typography.subtitle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            track.artist,
                            style: FluentTheme.of(context).typography.body,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    // Lyrics View
                    const Expanded(
                      flex: 6,
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: FluentLyricsView(),
                      ),
                    ),
                  ],
                ),
              ),
              // Playback Controls
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    FluentProgressBar(player: playback.player),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(FluentIcons.previous, size: 24),
                          onPressed: () => playback.previous(),
                        ),
                        const SizedBox(width: 32),
                        StreamBuilder<bool>(
                          stream: playback.player.stream.playing,
                          builder: (context, playingSnapshot) {
                            final playing = playingSnapshot.data ?? false;
                            return Button(
                              onPressed: () =>
                                  playing ? playback.pause() : playback.resume(),
                                style: ButtonStyle(
                                  padding: WidgetStateProperty.all(
                                      const EdgeInsets.all(12)),
                                  shape: WidgetStateProperty.all(const CircleBorder()),
                                ),
                              child: Icon(
                                playing ? FluentIcons.pause : FluentIcons.play,
                                size: 32,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 32),
                        IconButton(
                          icon: const Icon(FluentIcons.next, size: 24),
                          onPressed: () => playback.next(),
                        ),
                        const SizedBox(width: 32),
                        StreamBuilder<SearchResult?>(
                          stream: playback.currentTrackStream,
                          builder: (context, snapshot) {
                            final current = snapshot.data;
                            final isFavorite = current?.isVault ?? false;
                            return IconButton(
                              icon: Icon(
                                isFavorite
                                    ? FluentIcons.favorite_star_fill
                                    : FluentIcons.favorite_star,
                                color: isFavorite ? Colors.orange : null,
                                size: 24,
                              ),
                              onPressed: () => playback.toggleFavorite(),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class FluentProgressBar extends StatelessWidget {
  final Player player;
  const FluentProgressBar({super.key, required this.player});

  @override
  Widget build(BuildContext context) => StreamBuilder<Duration>(
        stream: player.stream.position,
        builder: (context, snapshot) {
          final position = snapshot.data ?? Duration.zero;
          final duration = player.state.duration;
          final maxVal =
              duration.inMilliseconds.toDouble().clamp(1.0, double.infinity);

          return Column(
            children: [
              Slider(
                value: position.inMilliseconds.toDouble().clamp(0, maxVal),
                max: maxVal,
                onChanged: (val) => PlaybackService.instance
                    .seek(Duration(milliseconds: val.toInt())),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(position)),
                  Text(_formatDuration(duration)),
                ],
              ),
            ],
          );
        },
      );

  String _formatDuration(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}

class FluentLyricsView extends StatelessWidget {
  const FluentLyricsView({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<List<LyricLine>>(
        stream: PlaybackService.instance.lyricsStream,
        builder: (context, snapshot) {
          final lyrics = snapshot.data ?? [];
          if (lyrics.isEmpty) {
            return Center(
                child: Text('Buscando letras...',
                    style: FluentTheme.of(context).typography.caption));
          }

          return StreamBuilder<Duration>(
            stream: PlaybackService.instance.player.stream.position,
            builder: (context, posSnapshot) {
              final position = posSnapshot.data ?? Duration.zero;
              return ListView.builder(
                itemCount: lyrics.length,
                itemBuilder: (context, index) {
                  final line = lyrics[index];
                  final isCurrent = index < lyrics.length - 1
                      ? position >= line.time &&
                          position < lyrics[index + 1].time
                      : position >= line.time;

                  return AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    textAlign: TextAlign.center,
                    style: isCurrent
                        ? (FluentTheme.of(context).typography.bodyLarge ?? const TextStyle()).copyWith(
                            fontWeight: FontWeight.bold,
                            color: FluentTheme.of(context).accentColor)
                        : (FluentTheme.of(context).typography.body ?? const TextStyle()),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 24),
                      child: Text(line.text),
                    ),
                  );
                },
              );
            },
          );
        },
      );
}
