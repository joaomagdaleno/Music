import 'package:fluent_ui/fluent_ui.dart';


/// Fluent UI view for PlaylistDetailScreen - WinUI 3 styling
class FluentPlaylistDetailView extends StatelessWidget {
  final String playlistName;
  final List<Map<String, dynamic>> tracks;
  final bool isLoading;
  final void Function(Map<String, dynamic>) onPlayTrack;

  const FluentPlaylistDetailView({
    super.key,
    required this.playlistName,
    required this.tracks,
    required this.isLoading,
    required this.onPlayTrack,
  });

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(title: Text(playlistName)),
      content: isLoading
          ? const Center(child: ProgressRing())
          : tracks.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(FluentIcons.music_note, size: 64, color: FluentTheme.of(context).inactiveColor), const SizedBox(height: 16), const Text('Esta playlist está vazia.')]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: FluentTheme.of(context).accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: track['thumbnail'] != null ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(track['thumbnail'], fit: BoxFit.cover)) : const Icon(FluentIcons.music_note)),
                        title: Text(track['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(track['artist'] ?? ''),
                        trailing: IconButton(icon: const Icon(FluentIcons.play), onPressed: () => onPlayTrack(track)),
                      ),
                    );
                  },
                ),
    );
  }
}
