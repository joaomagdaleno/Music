import 'package:flutter/material.dart';
import 'database_service.dart';
import 'download_service.dart';
import 'playback_service.dart';

class MoodExplorerView extends StatelessWidget {
  MoodExplorerView({super.key});

  final List<Map<String, dynamic>> _moods = [
    {'name': 'Energético', 'icon': Icons.flash_on, 'color': Colors.orange},
    {'name': 'Relaxante', 'icon': Icons.spa, 'color': Colors.teal},
    {'name': 'Foco', 'icon': Icons.center_focus_strong, 'color': Colors.blue},
    {
      'name': 'Melancólico',
      'icon': Icons.cloud_outlined,
      'color': Colors.indigo
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Qual o seu mood hoje?',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: _moods.length,
              itemBuilder: (context, index) {
                final mood = _moods[index];
                return _MoodCard(
                  name: mood['name'],
                  icon: mood['icon'],
                  color: mood['color'],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;

  const _MoodCard(
      {required this.name, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showMoodTracks(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoodTracks(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MoodTracksSheet(mood: name, color: color),
    );
  }
}

class _MoodTracksSheet extends StatelessWidget {
  final String mood;
  final Color color;

  const _MoodTracksSheet({required this.mood, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.2),
                    child: Icon(Icons.music_note, color: color)),
                const SizedBox(width: 16),
                Text(
                  'Mix $mood',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: DatabaseService.instance.getTracksByMood(mood),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final tracks = snapshot.data ?? [];
                if (tracks.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhuma música encontrada para este mood.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final trackData = tracks[index];
                    final track = SearchResult.fromJson(trackData);
                    return ListTile(
                      leading: track.thumbnail != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(track.thumbnail!,
                                  width: 48, height: 48, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.music_note),
                      title: Text(track.title),
                      subtitle: Text(track.artist),
                      onTap: () {
                        PlaybackService.instance.playSearchResult(track);
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
