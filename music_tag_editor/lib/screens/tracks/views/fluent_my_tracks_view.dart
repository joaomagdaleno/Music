import 'package:fluent_ui/fluent_ui.dart';
import 'package:music_tag_editor/services/download_service.dart';

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
  });

  @override
  State<FluentMyTracksView> createState() => _FluentMyTracksViewState();
}

class _FluentMyTracksViewState extends State<FluentMyTracksView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationView(
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
        actions: CommandBar(mainAxisAlignment: MainAxisAlignment.end, primaryItems: [
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
            body: _buildTrackList(context, 'audio'),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.video),
            title: const Text('Vídeos'),
            body: _buildTrackList(context, 'video'),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackList(BuildContext context, String mediaType) {
    if (widget.isLoading) {
      return const Center(child: ProgressRing());
    }

    final filteredTracks = widget.tracks.where((t) => t.mediaType == mediaType).toList();

    if (filteredTracks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              mediaType == 'audio' ? FluentIcons.music_note : FluentIcons.video,
              size: 64,
              color: FluentTheme.of(context).inactiveColor,
            ),
            const SizedBox(height: 16),
            Text('Nenhum(a) ${mediaType == 'audio' ? 'música' : 'vídeo'} salvo(a).'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTracks.length,
      itemBuilder: (context, index) {
        final track = filteredTracks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: FluentTheme.of(context).accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: track.thumbnail != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(track.thumbnail!, fit: BoxFit.cover))
                  : const Icon(FluentIcons.music_note),
            ),
            title: Text(track.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(track.artist),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(FluentIcons.play), onPressed: () => widget.onPlayTrack(track)),
              IconButton(icon: const Icon(FluentIcons.lock), onPressed: () => widget.onAddToVault(track)),
            ]),
            onPressed: () => widget.onPlayTrack(track),
          ),
        );
      },
    );
  }
}
