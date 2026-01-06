import 'package:flutter/material.dart';
import 'package:music_hub/models/search_models.dart';

/// Material Design view for MyTracksScreen
class MaterialMyTracksView extends StatelessWidget {
  final List<SearchResult> tracks;
  final bool isLoading;
  final void Function(SearchResult) onPlayTrack;
  final void Function(SearchResult) onAddToVault;
  final VoidCallback onImportPlaylist;

  const MaterialMyTracksView({
    super.key,
    required this.tracks,
    required this.isLoading,
    required this.onPlayTrack,
    required this.onAddToVault,
    required this.onImportPlaylist,
    this.currentTrack,
  });

  final SearchResult? currentTrack;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Biblioteca'),
          actions: [
            IconButton(
              icon: const Icon(Icons.playlist_add),
              onPressed: onImportPlaylist,
              tooltip: 'Importar Playlist',
            )
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildTrackList(context),
      );

  Widget _buildTrackList(BuildContext context) {
    if (tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text('Nenhuma música salva.'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: track.thumbnail != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(track.thumbnail!,
                          fit: BoxFit.cover, cacheWidth: 150))
                  : const Icon(Icons.music_note),
            ),
            title: Text(
              track.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: track.id == currentTrack?.id
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
            subtitle: Text(track.artist),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (track.id == currentTrack?.id)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.equalizer,
                        color: Theme.of(context).colorScheme.primary),
                  ),
                PopupMenuButton(
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'play',
                        child: ListTile(
                            leading: Icon(Icons.play_arrow),
                            title: Text('Tocar'))),
                    const PopupMenuItem(
                        value: 'vault',
                        child: ListTile(
                            leading: Icon(Icons.lock),
                            title: Text('Adicionar ao Cofre'))),
                  ],
                  onSelected: (v) =>
                      v == 'play' ? onPlayTrack(track) : onAddToVault(track),
                ),
              ],
            ),
            selected: track.id == currentTrack?.id,
            selectedTileColor: Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.3),
            onTap: () => onPlayTrack(track),
          ),
        );
      },
    );
  }
}
