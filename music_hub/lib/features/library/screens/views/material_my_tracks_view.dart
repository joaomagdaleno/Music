import 'package:flutter/material.dart';
import 'package:music_hub/features/library/models/search_models.dart';

class MaterialMyTracksView extends StatelessWidget {
  const MaterialMyTracksView({
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
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Nenhuma música na biblioteca.'),
            const SizedBox(height: 16),
            ElevatedButton(
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
          selected: isPlaying,
          leading: Icon(
            isPlaying ? Icons.play_arrow : Icons.music_note,
            color: isPlaying ? Theme.of(context).primaryColor : null,
          ),
          title: Text(track.title),
          subtitle: Text(track.artist),
          onTap: () => onPlayTrack(track),
          trailing: IconButton(
            icon: const Icon(Icons.security),
            onPressed: () => onAddToVault(track),
          ),
        );
      },
    );
  }
}
