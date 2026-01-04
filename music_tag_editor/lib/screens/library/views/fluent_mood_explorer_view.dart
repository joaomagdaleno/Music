import 'package:fluent_ui/fluent_ui.dart';

/// Fluent UI view for MoodExplorerScreen - WinUI 3 styling
class FluentMoodExplorerView extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> moodTracks;
  final bool isLoading;
  final void Function(Map<String, dynamic>) onPlayTrack;

  const FluentMoodExplorerView({
    super.key,
    required this.moodTracks,
    required this.isLoading,
    required this.onPlayTrack,
  });

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Explorar por Humor'),
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
      content: isLoading
          ? const Center(child: ProgressRing())
          : moodTracks.isEmpty
              ? const Center(child: Text('Nenhuma música analisada ainda.'))
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: moodTracks.entries.map((entry) => _buildMoodSection(context, entry.key, entry.value)).toList(),
                ),
    );
  }

  Widget _buildMoodSection(BuildContext context, String mood, List<Map<String, dynamic>> tracks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(mood, style: FluentTheme.of(context).typography.subtitle),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return Card(
                margin: const EdgeInsets.only(right: 12),
                padding: EdgeInsets.zero,
                child: GestureDetector(
                  onTap: () => onPlayTrack(track),
                  child: SizedBox(
                    width: 140,
                    child: Column(
                      children: [
                        Expanded(child: track['thumbnail'] != null ? ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(4)), child: Image.network(track['thumbnail'], fit: BoxFit.cover, width: double.infinity, cacheWidth: 420)) : const Center(child: Icon(FluentIcons.music_note, size: 32))),
                        Padding(padding: const EdgeInsets.all(8.0), child: Text(track['title'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
