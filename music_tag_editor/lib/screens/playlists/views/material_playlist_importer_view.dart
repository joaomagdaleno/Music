import 'package:flutter/material.dart';
import 'package:music_hub/models/search_models.dart';

/// Material Design view for PlaylistImporterScreen
class MaterialPlaylistImporterView extends StatelessWidget {
  final TextEditingController urlController;
  final List<SearchResult> tracks;
  final bool isLoading;
  final String? error;
  final VoidCallback onScan;
  final VoidCallback onImportAll;

  const MaterialPlaylistImporterView({
    super.key,
    required this.urlController,
    required this.tracks,
    required this.isLoading,
    required this.error,
    required this.onScan,
    required this.onImportAll,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Importador de Playlist')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                      labelText: 'URL da Playlist',
                      suffixIcon: IconButton(
                          icon: const Icon(Icons.search), onPressed: onScan),
                      border: const OutlineInputBorder())),
              const SizedBox(height: 20),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red))
              else if (tracks.isNotEmpty) ...[
                Expanded(
                  child: ListView.builder(
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      return ListTile(
                        leading: track.thumbnail != null
                            ? Image.network(track.thumbnail!,
                                width: 40, cacheWidth: 120)
                            : const Icon(Icons.music_note),
                        title: Text(track.title),
                        subtitle: Text(track.artist),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                    onPressed: onImportAll,
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50)),
                    child: Text('Importar ${tracks.length} Músicas')),
              ] else
                const Expanded(
                    child: Center(child: Text('Cole um link para começar.'))),
            ],
          ),
        ),
      );
}
