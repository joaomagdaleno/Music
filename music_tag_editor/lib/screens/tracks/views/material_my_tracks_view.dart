import 'package:flutter/material.dart';
import 'package:music_tag_editor/services/download_service.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Músicas'),
        actions: [IconButton(icon: const Icon(Icons.playlist_add), onPressed: onImportPlaylist, tooltip: 'Importar Playlist')],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tracks.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.music_off, size: 64, color: Colors.grey[400]), const SizedBox(height: 16), const Text('Nenhuma música salva.')]))
              : ListView.builder(
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(8)), child: track.thumbnail != null ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(track.thumbnail!, fit: BoxFit.cover)) : const Icon(Icons.music_note)),
                        title: Text(track.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(track.artist),
                        trailing: PopupMenuButton(itemBuilder: (_) => [
                          const PopupMenuItem(value: 'play', child: ListTile(leading: Icon(Icons.play_arrow), title: Text('Tocar'))),
                          const PopupMenuItem(value: 'vault', child: ListTile(leading: Icon(Icons.lock), title: Text('Adicionar ao Cofre'))),
                        ], onSelected: (v) => v == 'play' ? onPlayTrack(track) : onAddToVault(track)),
                        onTap: () => onPlayTrack(track),
                      ),
                    );
                  },
                ),
    );
  }
}
