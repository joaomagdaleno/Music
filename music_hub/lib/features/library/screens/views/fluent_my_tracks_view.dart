import 'package:fluent_ui/fluent_ui.dart';
import 'package:music_hub/features/library/models/search_models.dart';

class FluentMyTracksView extends StatelessWidget {
  const FluentMyTracksView({
    super.key,
    required this.tracks,
    required this.isLoading,
    required this.onPlayTrack,
    required this.onAddToVault,
    required this.onImportPlaylist,
    this.currentTrack,
  });

  final List<SearchResult> tracks;
  final bool isLoading;
  final Function(SearchResult) onPlayTrack;
  final Function(SearchResult) onAddToVault;
  final VoidCallback onImportPlaylist;
  final SearchResult? currentTrack;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: ProgressRing());
    if (tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nenhuma música na biblioteca.'),
            const SizedBox(height: 16),
            Button(
              onPressed: onImportPlaylist,
              child: const Text('Importar Playlist'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: tracks.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final track = tracks[index];
        final isPlaying = currentTrack?.id == track.id;

        return ListTile(
          onPressed: () => onPlayTrack(track),
          leading: Icon(
            isPlaying ? FluentIcons.play : FluentIcons.music_note,
            color: isPlaying ? Colors.blue : null,
          ),
          title: Text(
            track.title,
            style: TextStyle(
              fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
              color: isPlaying ? Colors.blue.darkest : null,
            ),
          ),
          subtitle: Text(track.artist),
          trailing: IconButton(
            icon: const Icon(FluentIcons.lock),
            onPressed: () => onAddToVault(track),
          ),
        );
      },
    );
  }
}
