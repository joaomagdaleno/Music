import 'package:fluent_ui/fluent_ui.dart';
import 'package:music_tag_editor/services/download_service.dart';

/// Fluent UI view for RemoteLibraryScreen - WinUI 3 styling
class FluentRemoteLibraryView extends StatelessWidget {
  final List<SearchResult> tracks;
  final bool isLoading;
  final VoidCallback onRefresh;
  final void Function(SearchResult) onPlayTrack;
  final void Function(SearchResult) onAddToQueue;

  const FluentRemoteLibraryView({
    super.key,
    required this.tracks,
    required this.isLoading,
    required this.onRefresh,
    required this.onPlayTrack,
    required this.onAddToQueue,
  });

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Biblioteca do Amigo'),
        commandBar: CommandBar(mainAxisAlignment: MainAxisAlignment.end, primaryItems: [
          CommandBarButton(icon: const Icon(FluentIcons.refresh), label: const Text('Atualizar'), onPressed: onRefresh),
        ]),
      ),
      content: isLoading
          ? const Center(child: ProgressRing())
          : tracks.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(FluentIcons.people, size: 64, color: FluentTheme.of(context).inactiveColor), const SizedBox(height: 16), const Text('Nenhuma música encontrada no seu amigo.')]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: FluentTheme.of(context).accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: track.thumbnail != null ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(track.thumbnail!, fit: BoxFit.cover)) : const Icon(FluentIcons.music_note)),
                        title: Text(track.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(track.artist),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: const Icon(FluentIcons.add), onPressed: () => onAddToQueue(track)),
                          IconButton(icon: const Icon(FluentIcons.play), onPressed: () => onPlayTrack(track)),
                        ]),
                      ),
                    );
                  },
                ),
    );
  }
}
