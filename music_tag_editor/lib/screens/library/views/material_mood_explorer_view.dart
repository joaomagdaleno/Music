import 'package:flutter/material.dart';

/// Material Design view for MoodExplorerScreen
class MaterialMoodExplorerView extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> moodTracks;
  final bool isLoading;
  final void Function(Map<String, dynamic>) onPlayTrack;

  const MaterialMoodExplorerView({
    super.key,
    required this.moodTracks,
    required this.isLoading,
    required this.onPlayTrack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explorar por Humor')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : moodTracks.isEmpty
              ? const Center(child: Text('Nenhuma música analisada ainda.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: moodTracks.entries.map((entry) => _buildMoodSection(context, entry.key, entry.value)).toList(),
                ),
    );
  }

  Widget _buildMoodSection(BuildContext context, String mood, List<Map<String, dynamic>> tracks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(mood, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tracks.length,
            itemBuilder: (context, index) {
              final track = tracks[index];
              return Card(
                margin: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () => onPlayTrack(track),
                  child: SizedBox(
                    width: 120,
                    child: Column(
                      children: [
                        Expanded(child: track['thumbnail'] != null ? ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(8)), child: Image.network(track['thumbnail'], fit: BoxFit.cover, width: double.infinity, cacheWidth: 360)) : const Center(child: Icon(Icons.music_note, size: 32))),
                        Padding(padding: const EdgeInsets.all(8.0), child: Text(track['title'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
