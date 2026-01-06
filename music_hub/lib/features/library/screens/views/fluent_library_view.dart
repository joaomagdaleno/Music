import 'package:fluent_ui/fluent_ui.dart';
import 'package:music_hub/features/library/models/search_models.dart';
import 'package:music_hub/features/library/screens/mood_explorer_screen.dart';
import 'package:music_hub/features/library/screens/my_tracks_screen.dart';
import 'package:music_hub/features/library/screens/ringtone_maker_screen.dart';
import 'package:music_hub/features/discovery/screens/discovery_screen.dart';
import 'package:music_hub/features/settings/screens/settings_screen.dart';
import 'package:music_hub/features/library/screens/smart_library_screen.dart';

class FluentLibraryView extends StatefulWidget {
  const FluentLibraryView({
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
                icon: Icon(widget.isGridView ? FluentIcons.view_all : FluentIcons.list),
                label: Text(widget.isGridView ? 'List View' : 'Grid View'),
                onPressed: widget.onToggleView,
              ),
              CommandBarButton(
                icon: const Icon(FluentIcons.sort),
                label: const Text('Sort'),
                onPressed: () {
                  _showSortMenu(context);
                },
              ),
              const CommandBarSeparator(),
              CommandBarButton(
                icon: const Icon(FluentIcons.download),
                label: const Text('Download'),
                onPressed: () {
                  Navigator.push(
                    context,
                    FluentPageRoute(builder: (context) => const DiscoveryScreen()),
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

    if (widget.isGridView) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: widget.musicTracks.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final track = widget.musicTracks[index];
          return HoverButton(
            onPressed: () {},
            builder: (context, states) => Column(
                children: [
                   Expanded(
                    child: Card(
                      padding: EdgeInsets.zero,
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              FluentIcons.music_note,
                              size: 48,
                              color: Colors.grey[100],
                            ),
                          ),
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: IconButton(
                              icon: const Icon(FluentIcons.more),
                              onPressed: () => _showContextMenu(context, track, index),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[100], fontSize: 12),
                  ),
                ],
              ),
          );
        },
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
          subtitle: Text(track.artist),
          trailing: IconButton(
            icon: const Icon(FluentIcons.more),
            onPressed: () {
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

  void _showSortMenu(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Sort By'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioButton(
              checked: widget.sortBy == 'title',
              content: const Text('Title'),
              onChanged: (v) {
                if (v) widget.onSortChanged('title');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            RadioButton(
              checked: widget.sortBy == 'artist',
              content: const Text('Artist'),
              onChanged: (v) {
                if (v) widget.onSortChanged('artist');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
            RadioButton(
              checked: widget.sortBy == 'year',
              content: const Text('Year/Album'),
              onChanged: (v) {
                if (v) widget.onSortChanged('year');
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          Button(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context, SearchResult track, int index) {
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
                          builder: (context) => RingtoneMakerScreen(track: track),
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
