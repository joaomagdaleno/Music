import 'package:flutter/material.dart';
import 'search_service.dart';
import 'download_service.dart';
import 'database_service.dart';

class PlaylistImporterView extends StatefulWidget {
  const PlaylistImporterView({super.key});

  @override
  State<PlaylistImporterView> createState() => _PlaylistImporterViewState();
}

class _PlaylistImporterViewState extends State<PlaylistImporterView> {
  final TextEditingController _urlController = TextEditingController();
  final SearchService _searchService = SearchService();
  List<SearchResult> _tracks = [];
  bool _isLoading = false;
  String? _error;

  Future<void> _import() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _tracks = [];
    });

    try {
      final results = await _searchService.importPlaylist(url);
      setState(() {
        _tracks = results;
        if (_tracks.isEmpty)
          _error = "Nenhuma música encontrada nesta Playlist.";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Erro ao carregar playlist: $e";
        _isLoading = false;
      });
    }
  }

  void _importAll() async {
    for (var track in _tracks) {
      await DatabaseService.instance.saveTrack(track.toJson());
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('${_tracks.length} músicas adicionadas à biblioteca!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importador de Playlist')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'URL da Playlist (Spotify ou YouTube)',
                hintText: 'https://...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: _import,
                ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red))
            else if (_tracks.isNotEmpty) ...[
              Expanded(
                child: ListView.builder(
                  itemCount: _tracks.length,
                  itemBuilder: (context, index) {
                    final track = _tracks[index];
                    return ListTile(
                      leading: Image.network(
                        track.thumbnail ?? 'https://via.placeholder.com/150',
                        width: 50,
                        fit: BoxFit.cover,
                      ),
                      title: Text(track.title),
                      subtitle: Text(track.artist),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _importAll,
                icon: const Icon(Icons.add_to_photos),
                label: Text('Importar ${_tracks.length} Músicas'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Text('Cole um link acima para escanear a playlist.'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
