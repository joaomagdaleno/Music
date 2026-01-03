import 'package:fluent_ui/fluent_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/lyrics_service.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/services/startup_logger.dart';

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
      content: StreamBuilder<SearchResult?>(
        stream: playback.currentTrackStream,
        builder: (context, snapshot) {
          final track = snapshot.data;
          if (track == null) return const Center(child: Text('Nenhuma música tocando'));

          return Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Album Art / Video
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Card(
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Video(controller: playback.videoController),
                              // Optional: Show album art if video is not available/loading?
                              // For now, media_kit handles black screen if no video track.
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(track.title, style: FluentTheme.of(context).typography.title, textAlign: TextAlign.center),
                      Text(track.artist, style: FluentTheme.of(context).typography.body, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      _buildResolutionSelector(context),
                    ],
                  ),
                ),
                // Controls & Lyrics
                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FluentProgressBar(player: playback.player),
                      const SizedBox(height: 24), // Reduced spacing
                      StreamBuilder<bool>(
                        stream: playback.player.stream.playing,
                        builder: (context, playingSnapshot) {
                          final playing = playingSnapshot.data ?? false;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(FluentIcons.previous, size: 20), // Smaller icon
                                onPressed: () => playback.player.previous(),
                              ),
                              const SizedBox(width: 16), // Smaller spacing
                              FilledButton(
                                onPressed: () => playing ? playback.pause() : playback.resume(),
                                style: ButtonStyle(
                                  padding: WidgetStateProperty.all(const EdgeInsets.all(12)), // Smaller padding
                                ),
                                child: Icon(playing ? FluentIcons.pause : FluentIcons.play, size: 24), // Smaller icon
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(FluentIcons.next, size: 20), // Smaller icon
                                onPressed: () => playback.player.next(),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
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

  Widget _buildResolutionSelector(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: PlaybackService.instance.currentTrack != null 
          ? SearchService.instance.getAvailableResolutions(PlaybackService.instance.currentTrack!.url)
          : Future.value(['Auto']),
      builder: (context, snapshot) {
        final resolutions = snapshot.data ?? ['Auto'];
        return DropDownButton(
          title: const Text('Resolução'),
          items: resolutions.map((r) => MenuFlyoutItem(
            text: Text(r),
            onPressed: () async {
              final track = PlaybackService.instance.currentTrack;
              if (track != null) {
                StartupLogger.log('Selected resolution: $r');
                // Implementation for changing resolution:
                // We fetch the new stream URL and open it at current position
                final newUrl = await SearchService.instance.getStreamUrl(track.url, resolution: r);
                if (newUrl != null) {
                   final position = PlaybackService.instance.player.state.position;
                   await PlaybackService.instance.player.open(Media(newUrl));
                   await PlaybackService.instance.player.seek(position);
                }
              }
            },
          )).toList(),
        );
      },
    );
  }
}

class FluentProgressBar extends StatelessWidget {
  final Player player;
  const FluentProgressBar({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: player.stream.position,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = player.state.duration;
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
          stream: PlaybackService.instance.player.stream.position,
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
