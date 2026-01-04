import 'package:fluent_ui/fluent_ui.dart';
import 'package:music_tag_editor/models/music_track.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/screens/library/mood_explorer_screen.dart';
import 'package:music_tag_editor/screens/tracks/my_tracks_screen.dart';
import 'package:music_tag_editor/screens/tracks/ringtone_maker_screen.dart';
import 'package:music_tag_editor/screens/search/search_screen.dart';
import 'package:music_tag_editor/screens/settings/settings_screen.dart';
import 'package:music_tag_editor/screens/library/smart_library_screen.dart';

class FluentLibraryView extends StatefulWidget {
  const FluentLibraryView({
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
  State<FluentLibraryView> createState() => _FluentLibraryViewState();
}

class _FluentLibraryViewState extends State<FluentLibraryView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) => ScaffoldPage(
        header: PageHeader(
          title: Text(widget.title),
          leading: Navigator.canPop(context)
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: IconButton(
                    icon: const Icon(FluentIcons.back),
                    onPressed: () => Navigator.pop(context),
                  ),
                )
              : null,
          commandBar: CommandBar(
            primaryItems: [
              CommandBarButton(
                icon: const Icon(FluentIcons.download),
                label: const Text('Download'),
                onPressed: () {
                  Navigator.push(
                    context,
                    FluentPageRoute(builder: (context) => const SearchScreen()),
                  );
                },
              ),
              CommandBarButton(
                icon: const Icon(FluentIcons.settings),
                label: const Text('Settings'),
                onPressed: () {
                  Navigator.push(
                    context,
                    FluentPageRoute(
                        builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
        content: TabView(
          currentIndex: _currentIndex,
          onChanged: (index) => setState(() => _currentIndex = index),
          closeButtonVisibility: CloseButtonVisibilityMode.never,
          tabs: [
            Tab(
              text: const Text('Pastas Local'),
              icon: const Icon(FluentIcons.folder_list),
              body: _buildFolderView(),
            ),
            Tab(
              text: const Text('Minha Biblioteca'),
              icon: const Icon(FluentIcons.music_note),
              body: const MyTracksScreen(),
            ),
            Tab(
              text: const Text('Smart Mix'),
              icon: const Icon(FluentIcons.library),
              body: const SmartLibraryScreen(),
            ),
            Tab(
              text: const Text('Mood Explorer'),
              icon: const Icon(FluentIcons.emoji_neutral),
              body: const MoodExplorerScreen(),
            ),
          ],
        ),
      );

  Widget _buildFolderView() {
    if (widget.isLoading) {
      return const Center(child: ProgressRing());
    }

    if (widget.musicTracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Nenhuma pasta selecionada.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: widget.onAddFolder,
              child: const Text('Selecionar Pasta'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.musicTracks.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final track = widget.musicTracks[index];
        return ListTile(
          leading: const Icon(FluentIcons.music_note),
          title: Text(track.title),
          subtitle: Text('${track.artist} - ${track.album}'),
          trailing: IconButton(
            icon: const Icon(FluentIcons.more),
            onPressed: () {
              // Show flyout or context menu
              _showContextMenu(context, track, index);
            },
          ),
          onPressed: () {
            // Selection logic
          },
        );
      },
    );
  }

  void _showContextMenu(BuildContext context, MusicTrack track, int index) {
    // Implementation of context menu using Flyout or similar would go here
    // For brevity, we can just trigger actions directly or keep it simple
    showDialog(
        context: context,
        builder: (context) => ContentDialog(
              title: Text(track.title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Button(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        FluentPageRoute(
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
                    },
                    child: const Text('Criar Toque'),
                  ),
                  const SizedBox(height: 8),
                  Button(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onSearchOnline(track);
                    },
                    child: const Text('Buscar Metadados'),
                  ),
                  const SizedBox(height: 8),
                  Button(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onEditTrack(track);
                    },
                    child: const Text('Editar Manualmente'),
                  ),
                ],
              ),
              actions: [
                Button(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ));
  }
}
