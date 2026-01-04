import 'package:flutter/material.dart';

/// Material Design view for PlaylistDetailScreen
class MaterialPlaylistDetailView extends StatelessWidget {
  final String playlistName;
  final List<Map<String, dynamic>> tracks;
  final bool isLoading;
  final void Function(Map<String, dynamic>) onPlayTrack;

  const MaterialPlaylistDetailView({
    super.key,
    required this.playlistName,
    required this.tracks,
    required this.isLoading,
    required this.onPlayTrack,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(playlistName)),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : tracks.isEmpty
                ? const Center(child: Text('Playlist vazia.'))
                : ListView.builder(
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      return ListTile(
                        leading: track['thumbnail'] != null
                            ? Image.network(track['thumbnail'],
                                width: 40, cacheWidth: 150)
                            : const Icon(Icons.music_note),
                        title: Text(track['title']),
                        subtitle: Text(track['artist'] ?? ''),
                        trailing: IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () => onPlayTrack(track)),
                      );
                    },
                  ),
      );
}
