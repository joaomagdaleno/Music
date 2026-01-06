import 'package:flutter/material.dart';
import 'package:music_hub/models/search_models.dart';
import 'package:music_hub/features/library/screens/mood_explorer_screen.dart';
import 'package:music_hub/features/library/screens/my_tracks_screen.dart';
import 'package:music_hub/features/library/screens/ringtone_maker_screen.dart';
import 'package:music_hub/features/discovery/screens/discovery_screen.dart';
import 'package:music_hub/screens/settings/settings_screen.dart';
import 'package:music_hub/features/library/screens/smart_library_screen.dart';

class MaterialLibraryView extends StatelessWidget {
  const MaterialLibraryView({
    super.key,
    required this.title,
    required this.isLoading,
    required this.musicTracks,
    required this.isGridView,
    required this.sortBy,
    required this.onAddFolder,
    required this.onSearchOnline,
    required this.onEditTrack,
    required this.onToggleView,
    required this.onSortChanged,
  });

  final String title;
  final bool isLoading;
  final List<SearchResult> musicTracks;
  final bool isGridView;
  final String sortBy;
  final VoidCallback onAddFolder;
  final Function(SearchResult) onSearchOnline;
  final Function(SearchResult) onEditTrack;
  final VoidCallback onToggleView;
  final Function(String) onSortChanged;

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Text(title),
            actions: [
              IconButton(
                icon: Icon(isGridView ? Icons.view_module : Icons.view_list),
                onPressed: onToggleView,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort),
                onSelected: onSortChanged,
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'title', child: Text('Sort by Title')),
                  const PopupMenuItem(value: 'artist', child: Text('Sort by Artist')),
                  const PopupMenuItem(value: 'year', child: Text('Sort by Year')),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Download Music',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const DiscoveryScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ],
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Pastas Local'),
                Tab(text: 'Minha Biblioteca'),
                Tab(text: 'Smart Mix'),
                Tab(text: 'Mood Explorer'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildFolderView(context),
              const MyTracksScreen(),
              const SmartLibraryScreen(),
              const MoodExplorerScreen(),
            ],
          ),
        ),
      );

  Widget _buildFolderView(BuildContext context) => Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : musicTracks.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Nenhuma pasta selecionada.'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: onAddFolder,
                        child: const Text('Selecionar Pasta'),
                      ),
                    ],
                  )
                : isGridView
                    ? GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1,
                        ),
                        itemCount: musicTracks.length,
                        itemBuilder: (context, index) {
                          final track = musicTracks[index];
                          return Card(
                            child: InkWell(
                              onTap: () {},
                              onLongPress: () => onEditTrack(track),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.music_note, size: 48),
                                  const SizedBox(height: 8),
                                  Text(track.title,
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(track.artist,
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        itemCount: musicTracks.length,
                        itemBuilder: (context, index) {
                          final track = musicTracks[index];
                          return ListTile(
                            leading: const Icon(Icons.music_note),
                            title: Text(track.title),
                            subtitle: Text(track.artist),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'ringtone') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RingtoneMakerScreen(
                                        track: track,
                                      ),
                                    ),
                                  );
                                } else if (value == 'search') {
                                  onSearchOnline(track);
                                } else if (value == 'edit') {
                                  onEditTrack(track);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'ringtone',
                                  child: ListTile(
                                    leading: Icon(Icons.content_cut),
                                    title: Text('Criar Toque'),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'search',
                                  child: ListTile(
                                    leading: Icon(Icons.search),
                                    title: Text('Buscar Metadados'),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit),
                                    title: Text('Editar Manualmente'),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              // Selection logic or play
                            },
                            onLongPress: () => onEditTrack(track),
                          );
                        },
                      ),
      );
}
