import 'package:flutter/material.dart';
import 'package:music_tag_editor/models/music_track.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/screens/mood/mood_explorer_screen.dart';
import 'package:music_tag_editor/screens/tracks/my_tracks_screen.dart';
import 'package:music_tag_editor/screens/tracks/ringtone_maker_screen.dart';
import 'package:music_tag_editor/screens/search/search_screen.dart';
import 'package:music_tag_editor/screens/settings/settings_screen.dart';
import 'package:music_tag_editor/screens/library/smart_library_screen.dart';

class MaterialLibraryView extends StatelessWidget {
  const MaterialLibraryView({
    super.key,
    required this.title,
    required this.isLoading,
    required this.musicTracks,
    required this.onAddFolder,
    required this.onSearchOnline,
    required this.onEditTrack,
  });

  final String title;
  final bool isLoading;
  final List<MusicTrack> musicTracks;
  final VoidCallback onAddFolder;
  final Function(MusicTrack) onSearchOnline;
  final Function(MusicTrack) onEditTrack;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(title),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Download Music',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
            MoodExplorerScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderView(BuildContext context) {
    return Center(
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
              : ListView.builder(
                  itemCount: musicTracks.length,
                  itemBuilder: (context, index) {
                    final track = musicTracks[index];
                    return ListTile(
                      leading: const Icon(Icons.music_note),
                      title: Text(track.title),
                      subtitle: Text('${track.artist} - ${track.album}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'ringtone') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RingtoneMakerScreen(
                                  track: SearchResult(
                                    id: index.toString(),
                                    title: track.title,
                                    artist: track.artist,
                                    url: '',
                                    platform: MediaPlatform.unknown,
                                    thumbnail: 'https://via.placeholder.com/150',
                                    localPath: track.filePath,
                                    genre: 'Unknown',
                                  ),
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
}
