import 'package:fluent_ui/fluent_ui.dart';
import 'package:music_tag_editor/models/search_models.dart';

/// Fluent UI view for PlaylistImporterScreen - WinUI 3 styling
class FluentPlaylistImporterView extends StatelessWidget {
  final TextEditingController urlController;
  final List<SearchResult> tracks;
  final bool isLoading;
  final String? error;
  final VoidCallback onScan;
  final VoidCallback onImportAll;

  const FluentPlaylistImporterView({
    super.key,
    required this.urlController,
    required this.tracks,
    required this.isLoading,
    required this.error,
    required this.onScan,
    required this.onImportAll,
  });

  @override
  Widget build(BuildContext context) => ScaffoldPage(
        header: PageHeader(
          title: const Text('Importador de Playlist'),
          leading: Navigator.canPop(context)
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: IconButton(
                    icon: const Icon(FluentIcons.back),
                    onPressed: () => Navigator.pop(context),
                  ),
                )
              : null,
        ),
        content: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: TextBox(
                          controller: urlController,
                          placeholder: 'URL da Playlist (Spotify ou YouTube)',
                          suffix: IconButton(
                              icon: const Icon(FluentIcons.search),
                              onPressed: onScan))),
                  const SizedBox(width: 12),
                  Button(onPressed: onScan, child: const Text('Escanear')),
                ],
              ),
              const SizedBox(height: 24),
              if (isLoading)
                const Center(child: ProgressRing())
              else if (error != null)
                InfoBar(
                    title: const Text('Erro'),
                    content: Text(error!),
                    severity: InfoBarSeverity.error)
              else if (tracks.isNotEmpty) ...[
                Expanded(
                  child: ListView.builder(
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: FluentTheme.of(context)
                                      .accentColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4)),
                              child: track.thumbnail != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(track.thumbnail!,
                                          fit: BoxFit.cover, cacheWidth: 120))
                                  : const Icon(FluentIcons.music_note)),
                          title: Text(track.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(track.artist),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: onImportAll,
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('Importar ${tracks.length} Músicas'))),
              ] else
                Expanded(
                    child: Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(FluentIcons.cloud_download,
                      size: 64, color: FluentTheme.of(context).inactiveColor),
                  const SizedBox(height: 16),
                  const Text('Cole um link para começar.')
                ]))),
            ],
          ),
        ),
      );
}
