import 'package:flutter/material.dart';
import 'package:music_tag_editor/services/download_service.dart';

/// Material Design view for SmartLibraryScreen
class MaterialSmartLibraryView extends StatelessWidget {
  final Future<List<SearchResult>> topHitsFuture;
  final Future<List<SearchResult>> recentDiscoveriesFuture;
  final void Function(SearchResult) onPlayTrack;

  const MaterialSmartLibraryView({
    super.key,
    required this.topHitsFuture,
    required this.recentDiscoveriesFuture,
    required this.onPlayTrack,
  });

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Biblioteca Inteligente'),
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.trending_up), text: 'Top Hits'),
                Tab(icon: Icon(Icons.history), text: 'Recentes'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _SmartList(
                  future: topHitsFuture,
                  onPlayTrack: onPlayTrack,
                  emptyText: 'Dê o play em algumas músicas primeiro!'),
              _SmartList(
                  future: recentDiscoveriesFuture,
                  onPlayTrack: onPlayTrack,
                  emptyText: 'Suas novas músicas aparecerão aqui.'),
            ],
          ),
        ),
      );
}

class _SmartList extends StatelessWidget {
  final Future<List<SearchResult>> future;
  final void Function(SearchResult) onPlayTrack;
  final String emptyText;

  const _SmartList(
      {required this.future,
      required this.onPlayTrack,
      required this.emptyText});

  @override
  Widget build(BuildContext context) => FutureBuilder<List<SearchResult>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tracks = snapshot.data ?? [];
          if (tracks.isEmpty) {
            return Center(
                child: Text(emptyText,
                    style: const TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
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
                onTap: () => onPlayTrack(track),
              );
            },
          );
        },
      );
}
