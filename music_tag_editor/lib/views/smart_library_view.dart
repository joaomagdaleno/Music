import 'package:flutter/material.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/download_service.dart';

class SmartLibraryView extends StatelessWidget {
  const SmartLibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.trending_up), text: 'Top Hits'),
              Tab(icon: Icon(Icons.history), text: 'Descobertas Recentes'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _SmartList(
                  future: DatabaseService.instance.getMostPlayed(),
                  emptyText:
                      'Toque algumas músicas para ver suas favoritas aqui!',
                ),
                _SmartList(
                  future: DatabaseService.instance.getRecentlyPlayed(),
                  emptyText:
                      'Suas músicas ouvidas recentemente aparecerão aqui.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartList extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> future;
  final String emptyText;

  const _SmartList({required this.future, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final tracks = snapshot.data ?? [];
        if (tracks.isEmpty) {
          return Center(
              child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(emptyText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
          ));
        }

        return ListView.builder(
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final t = tracks[index];
            final result = SearchResult(
              id: t['id'],
              title: t['title'],
              artist: t['artist'] ?? '',
              thumbnail: t['thumbnail'],
              duration: t['duration'] as int?,
              url: t['url'],
              platform: MediaPlatform.values.firstWhere(
                (e) => e.toString() == t['platform'],
                orElse: () => MediaPlatform.unknown,
              ),
              localPath: t['local_path'],
              genre: t['genre'],
            );

            return ListTile(
              leading: result.thumbnail != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(result.thumbnail!,
                          width: 40, height: 40, fit: BoxFit.cover))
                  : const Icon(Icons.music_note),
              title: Text(result.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle:
                  Text("${result.artist} • ${t['play_count'] ?? 0} plays"),
              onTap: () => PlaybackService.instance.playSearchResult(result),
            );
          },
        );
      },
    );
  }
}

