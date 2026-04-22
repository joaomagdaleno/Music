import 'package:flutter/material.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/views/playlist_importer_view.dart';

class MyTracksView extends StatefulWidget {
  const MyTracksView({super.key});

  @override
  State<MyTracksView> createState() => _MyTracksViewState();
}

class _MyTracksViewState extends State<MyTracksView> {
  final DatabaseService _dbService = DatabaseService.instance;
  List<Map<String, dynamic>> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    final tracks = await _dbService.getTracks();
    setState(() {
      _tracks = tracks;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Músicas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Importar Playlist',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PlaylistImporterView()),
              );
              _loadTracks(); // Refresh after import
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tracks.isEmpty
              ? const Center(
                  child: Text(
                      'Nenhuma música salva ainda. Comece buscando e adicionando à sua biblioteca!'))
              : ListView.builder(
                  itemCount: _tracks.length,
                  itemBuilder: (context, index) {
                    final track = _tracks[index];
                    return ListTile(
                      leading: track['thumbnail'] != null
                          ? Image.network(track['thumbnail'],
                              width: 40, height: 40, errorBuilder: (_, __, ___) => const Icon(Icons.music_note))
                          : const Icon(Icons.music_note),
                      title: Text(track['title']),
                      subtitle: Text(track['artist'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.info_outline),
                        onPressed: () {
                          // Could open edit dialog or show info
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

