import 'package:flutter/material.dart';
import 'package:music_tag_editor/screens/playlists/playlist_detail_screen.dart';

/// Material Design view for PlaylistsScreen
class MaterialPlaylistsView extends StatelessWidget {
  final List<Map<String, dynamic>> playlists;
  final VoidCallback onCreatePlaylist;

  const MaterialPlaylistsView({
    super.key,
    required this.playlists,
    required this.onCreatePlaylist,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Playlists')),
        body: playlists.isEmpty
            ? const Center(child: Text('Você ainda não tem playlists.'))
            : ListView.builder(
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final p = playlists[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.playlist_play,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      title: Text(p['name'] ?? 'Sem nome',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle:
                          Text(p['description'] ?? 'Playlist personalizada'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PlaylistDetailScreen(
                                  playlistId: p['id'],
                                  playlistName: p['name']))),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: onCreatePlaylist,
          child: const Icon(Icons.add),
        ),
      );
}
