import 'package:flutter/material.dart';
import 'database_service.dart';
import 'playlist_detail_screen.dart';

class PlaylistsView extends StatefulWidget {
  const PlaylistsView({super.key});

  @override
  State<PlaylistsView> createState() => _PlaylistsViewState();
}

class _PlaylistsViewState extends State<PlaylistsView> {
  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> _playlists = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final playlists = await _dbService.getPlaylists();
    setState(() => _playlists = playlists);
  }

  void _createPlaylist() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nome da playlist'),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Criar')),
        ],
      ),
    );

    if (name != null && name.trim().isNotEmpty) {
      await _dbService.createPlaylist(name.trim());
      _loadPlaylists();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playlists')),
      body: _playlists.isEmpty
          ? const Center(child: Text('Você ainda não tem playlists.'))
          : ListView.builder(
              itemCount: _playlists.length,
              itemBuilder: (context, index) {
                final p = _playlists[index];
                return ListTile(
                  leading: const Icon(Icons.playlist_play),
                  title: Text(p['name'] ?? 'Sem nome'),
                  subtitle: Text(p['description'] ?? 'Playlist personalizada'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaylistDetailScreen(
                          playlistId: p['id'],
                          playlistName: p['name'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPlaylist,
        child: const Icon(Icons.add),
      ),
    );
  }
}
