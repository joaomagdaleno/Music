import 'package:flutter/material.dart';
import 'listening_stats_service.dart';

class ListeningStatsView extends StatefulWidget {
  const ListeningStatsView({super.key});

  @override
  State<ListeningStatsView> createState() => _ListeningStatsViewState();
}

class _ListeningStatsViewState extends State<ListeningStatsView> {
  ListeningStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await ListeningStatsService.instance.getStats();
    setState(() {
      _stats = stats;
      _isLoading = false;
    });
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes} minutos';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Suas Estatísticas'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Stats Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.tertiary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.headphones,
                            size: 48, color: Colors.white),
                        const SizedBox(height: 16),
                        Text(
                          _formatDuration(_stats!.estimatedListeningTime),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'de música ouvida',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatBadge(
                                '${_stats!.totalTracks}', 'músicas'),
                            _buildStatBadge('${_stats!.totalPlays}', 'plays'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Top Artists
                  if (_stats!.topArtists.isNotEmpty) ...[
                    const Text(
                      'Top Artistas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._stats!.topArtists.asMap().entries.map((entry) {
                      final i = entry.key;
                      final artist = entry.value;
                      return _buildRankItem(
                        rank: i + 1,
                        title: artist.key,
                        subtitle: '${artist.value} plays',
                        color: _getRankColor(i),
                      );
                    }),
                  ],

                  const SizedBox(height: 24),

                  // Top Tracks
                  if (_stats!.topTracks.isNotEmpty) ...[
                    const Text(
                      'Top Músicas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._stats!.topTracks.asMap().entries.map((entry) {
                      final i = entry.key;
                      final track = entry.value;
                      return _buildRankItem(
                        rank: i + 1,
                        title: track['title'] ?? 'Unknown',
                        subtitle:
                            '${track['artist'] ?? 'Unknown'} • ${track['play_count'] ?? 0} plays',
                        color: _getRankColor(i),
                        thumbnail: track['thumbnail'],
                      );
                    }),
                  ],

                  const SizedBox(height: 24),

                  // Top Genres
                  if (_stats!.topGenres.isNotEmpty) ...[
                    const Text(
                      'Top Gêneros',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _stats!.topGenres.map((genre) {
                        return Chip(
                          label: Text('${genre.key} (${genre.value})'),
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildStatBadge(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _buildRankItem({
    required int rank,
    required String title,
    required String subtitle,
    required Color color,
    String? thumbnail,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (thumbnail != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                thumbnail,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.music_note, color: Colors.white54),
              ),
            ),
          if (thumbnail != null) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey;
      case 2:
        return Colors.brown;
      default:
        return Colors.blueGrey;
    }
  }
}
