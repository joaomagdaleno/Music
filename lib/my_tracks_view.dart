import 'package:flutter/material.dart';
import 'database_service.dart';
import 'playback_service.dart';
import 'download_service.dart';
import 'playlist_importer_view.dart';

class MyTracksView extends StatefulWidget {
  const MyTracksView({super.key});

  @override
  State<MyTracksView> createState() => _MyTracksViewState();
}

class _MyTracksViewState extends State<MyTracksView> {
  final DatabaseService _dbService = DatabaseService.instance;
  final PlaybackService _playbackService = PlaybackService.instance;
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

  void _playTrack(Map<String, dynamic> trackData) {
    final result = SearchResult(
      id: trackData['id'],
      title: trackData['title'],
      artist: trackData['artist'] ?? '',
      thumbnail: trackData['thumbnail'],
      duration: trackData['duration'],
      url: trackData['url'],
      platform: MediaPlatform.values.firstWhere(
        (e) => e.toString() == trackData['platform'],
        orElse: () => MediaPlatform.unknown,
      ),
      localPath: trackData['local_path'],
    );
    _playbackService.playSearchResult(result);
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
                              width: 40, height: 40)
                          : const Icon(Icons.music_note),
                      title: Text(track['title']),
                      subtitle: Text(track['artist'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _playTrack(track),
                      ),
                    );
                  },
                ),
    );
  }
}
