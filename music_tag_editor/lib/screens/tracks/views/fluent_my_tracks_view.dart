import 'package:fluent_ui/fluent_ui.dart';
import 'package:music_hub/models/search_models.dart';

/// Fluent UI view for MyTracksScreen - WinUI 3 styling
class FluentMyTracksView extends StatefulWidget {
  final List<SearchResult> tracks;
  final bool isLoading;
  final void Function(SearchResult) onPlayTrack;
  final void Function(SearchResult) onAddToVault;
  final VoidCallback onImportPlaylist;

  const FluentMyTracksView({
    super.key,
    required this.tracks,
    required this.isLoading,
    required this.onPlayTrack,
    required this.onAddToVault,
    required this.onImportPlaylist,
    this.currentTrack,
  });

  final SearchResult? currentTrack;

  @override
  State<FluentMyTracksView> createState() => _FluentMyTracksViewState();
}

class _FluentMyTracksViewState extends State<FluentMyTracksView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) => NavigationView(
        appBar: NavigationAppBar(
          title: const Text('Biblioteca'),
          automaticallyImplyLeading: false,
          leading: Navigator.canPop(context)
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: IconButton(
                    icon: const Icon(FluentIcons.back),
                    onPressed: () => Navigator.pop(context),
                  ),
                )
              : null,
          actions: CommandBar(
              mainAxisAlignment: MainAxisAlignment.end,
              primaryItems: [
                CommandBarButton(
                  icon: const Icon(FluentIcons.download),
                  label: const Text('Importar Playlist'),
                  onPressed: widget.onImportPlaylist,
                ),
              ]),
        ),
        pane: NavigationPane(
          selected: _currentIndex,
          onChanged: (index) => setState(() => _currentIndex = index),
          displayMode: PaneDisplayMode.top,
          items: [
            PaneItem(
              icon: const Icon(FluentIcons.music_note),
              title: const Text('Músicas'),
              body: _buildTrackList(context),
            ),
          ],
        ),
      );

  Widget _buildTrackList(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: ProgressRing());
    }

    if (widget.tracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FluentIcons.music_note,
              size: 64,
              color: FluentTheme.of(context).inactiveColor,
            ),
            const SizedBox(height: 16),
            const Text('Nenhuma música salva.'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.tracks.length,
      itemBuilder: (context, index) {
        final track = widget.tracks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    FluentTheme.of(context).accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: track.thumbnail != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(track.thumbnail!,
                          fit: BoxFit.cover, cacheWidth: 150))
                  : const Icon(FluentIcons.music_note),
            ),
            title: Text(
              track.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: track.id == widget.currentTrack?.id
                    ? FluentTheme.of(context).accentColor
                    : null,
              ),
            ),
            subtitle: Text(track.artist),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              if (track.id == widget.currentTrack?.id)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(FluentIcons.music_in_collection,
                      color: FluentTheme.of(context).accentColor),
                ),
              IconButton(
                  icon: const Icon(FluentIcons.play),
                  onPressed: () => widget.onPlayTrack(track)),
              IconButton(
                  icon: const Icon(FluentIcons.lock),
                  onPressed: () => widget.onAddToVault(track)),
            ]),
            onPressed: () => widget.onPlayTrack(track),
            tileColor: track.id == widget.currentTrack?.id
                ? WidgetStateProperty.all(
                    FluentTheme.of(context).accentColor.withValues(alpha: 0.1))
                : null,
          ),
        );
      },
    );
  }
}
