import 'package:fluent_ui/fluent_ui.dart';

import 'package:music_tag_editor/screens/playlists/playlist_detail_screen.dart';

/// Fluent UI view for PlaylistsScreen
class FluentPlaylistsView extends StatelessWidget {
  final List<Map<String, dynamic>> playlists;
  final VoidCallback onCreatePlaylist;

  const FluentPlaylistsView({
    super.key,
    required this.playlists,
    required this.onCreatePlaylist,
  });

  @override
  Widget build(BuildContext context) => ScaffoldPage(
        header: PageHeader(
          title: const Text('Playlists'),
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
            mainAxisAlignment: MainAxisAlignment.end,
            primaryItems: [
              CommandBarButton(
                icon: const Icon(FluentIcons.add),
                label: const Text('Nova Playlist'),
                onPressed: onCreatePlaylist,
              ),
            ],
          ),
        ),
        content: playlists.isEmpty
            ? const Center(child: Text('Você ainda não tem playlists.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final p = playlists[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: FluentTheme.of(context)
                              .accentColor
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(FluentIcons.playlist_music,
                            color: FluentTheme.of(context).accentColor),
                      ),
                      title: Text(p['name'] ?? 'Sem nome',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle:
                          Text(p['description'] ?? 'Playlist personalizada'),
                      trailing: const Icon(FluentIcons.chevron_right),
                      onPressed: () => Navigator.push(
                          context,
                          FluentPageRoute(
                              builder: (_) => PlaylistDetailScreen(
                                  playlistId: p['id'],
                                  playlistName: p['name']))),
                    ),
                  );
                },
              ),
      );
}
