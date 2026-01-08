import 'package:fluent_ui/fluent_ui.dart';
import 'package:music_hub/features/library/models/search_models.dart';

/// Fluent UI view for SmartLibraryScreen - WinUI 3 styling
class FluentSmartLibraryView extends StatefulWidget {
  final Future<List<SearchResult>> topHitsFuture;
  final Future<List<SearchResult>> recentDiscoveriesFuture;
  final void Function(SearchResult) onPlayTrack;

  const FluentSmartLibraryView({
    super.key,
    required this.topHitsFuture,
    required this.recentDiscoveriesFuture,
    required this.onPlayTrack,
  });

  @override
  State<FluentSmartLibraryView> createState() => _FluentSmartLibraryViewState();
}

class _FluentSmartLibraryViewState extends State<FluentSmartLibraryView> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) => ScaffoldPage(
        header: PageHeader(
          title: const Text('Biblioteca Inteligente'),
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
        content: TabView(
          currentIndex: _currentIndex,
          onChanged: (index) => setState(() => _currentIndex = index),
          closeButtonVisibility: CloseButtonVisibilityMode.never,
          tabs: [
            Tab(
              text: const Text('Top Hits'),
              icon: const Icon(FluentIcons.favorite_list),
              body: _SmartList(
                  future: widget.topHitsFuture,
                  onPlayTrack: widget.onPlayTrack,
                  emptyText: 'Dê o play em algumas músicas primeiro!'),
            ),
            Tab(
              text: const Text('Descobertas Recentes'),
              icon: const Icon(FluentIcons.history),
              body: _SmartList(
                  future: widget.recentDiscoveriesFuture,
                  onPlayTrack: widget.onPlayTrack,
                  emptyText: 'Suas novas músicas aparecerão aqui.'),
            ),
          ],
        ),
      );
}

class _SmartList extends StatelessWidget {
  final Future<List<SearchResult>> future;
  final void Function(SearchResult) onPlayTrack;
  final String emptyText;

  const _SmartList(
      {required this.future,
      required this.onPlayTrack,
      required this.emptyText});

  @override
  Widget build(BuildContext context) => FutureBuilder<List<SearchResult>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: ProgressRing());
          }
          final tracks = snapshot.data ?? [];
          if (tracks.isEmpty) {
            return Center(
                child: Text(emptyText,
                    style: TextStyle(
                        color: FluentTheme.of(context).inactiveColor)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                          color: FluentTheme.of(context)
                              .accentColor
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: track.thumbnail != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(track.thumbnail!,
                                  fit: BoxFit.cover, cacheWidth: 150))
                          : const Icon(FluentIcons.music_note)),
                  title: Text(track.title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(track.artist),
                  onPressed: () => onPlayTrack(track),
                ),
              );
            },
          );
        },
      );
}
