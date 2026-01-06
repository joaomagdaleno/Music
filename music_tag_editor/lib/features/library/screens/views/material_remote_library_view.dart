import 'package:flutter/material.dart';
import 'package:music_hub/models/search_models.dart';

/// Material Design view for RemoteLibraryScreen
class MaterialRemoteLibraryView extends StatelessWidget {
  final List<SearchResult> tracks;
  final bool isLoading;
  final VoidCallback onRefresh;
  final void Function(SearchResult) onPlayTrack;
  final void Function(SearchResult) onAddToQueue;

  const MaterialRemoteLibraryView({
    super.key,
    required this.tracks,
    required this.isLoading,
    required this.onRefresh,
    required this.onPlayTrack,
    required this.onAddToQueue,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Biblioteca do Amigo'), actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: onRefresh)
        ]),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : tracks.isEmpty
                ? const Center(child: Text('Nenhuma música encontrada.'))
                : ListView.builder(
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      return ListTile(
                        leading: track.thumbnail != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(track.thumbnail!,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    cacheWidth: 120))
                            : const Icon(Icons.music_note),
                        title: Text(track.title),
                        subtitle: Text(track.artist),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.add_to_photos),
                                onPressed: () => onAddToQueue(track)),
                            IconButton(
                                icon: const Icon(Icons.play_arrow),
                                onPressed: () => onPlayTrack(track)),
                          ],
                        ),
                      );
                    },
                  ),
      );
}
