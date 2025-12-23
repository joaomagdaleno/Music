import 'package:flutter/material.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/views/mood_explorer_view.dart';
import 'package:music_tag_editor/views/smart_library_view.dart';
import 'package:music_tag_editor/views/listening_stats_view.dart';
import 'package:music_tag_editor/views/disco_mode_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final DatabaseService _dbService = DatabaseService.instance;
  final PlaybackService _playbackService = PlaybackService.instance;
  List<Map<String, dynamic>> _recentTracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final tracks = await _dbService.getTracks();
    // Sort by id descending as a proxy for recency (recently added)
    // In a real app we'd have an added_at column
    final sorted = List<Map<String, dynamic>>.from(tracks);
    // Assuming higher ID is newer if auto-increment, but UUIDs are random.
    // We'll just take the list as is for now, or shuffle.
    // Actually, let's reverse it to pretend last added are first if insertion order preserved by DB query
    setState(() {
      _recentTracks = sorted.reversed.take(5).toList();
      _isLoading = false;
    });
  }

  void _playTrack(Map<String, dynamic> trackData) {
    final result = SearchResult(
      id: trackData['id'],
      title: trackData['title'],
      artist: trackData['artist'] ?? '',
      thumbnail: trackData['thumbnail'],
      duration: trackData['duration'],
      url: trackData['url'],
      platform: MediaPlatform.values.firstWhere(
        (e) => e.toString() == trackData['platform'],
        orElse: () => MediaPlatform.unknown,
      ),
      localPath: trackData['local_path'],
    );
    _playbackService.playSearchResult(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DiscoModeView()),
            ),
            tooltip: 'Modo Disco',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting / Quick Actions Widget
                  _buildGreetingWidget(),
                  const SizedBox(height: 24),

                  // Moods Widget
                  const Text('Explore por Vibe',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const _MoodsWidget(),
                  const SizedBox(height: 24),

                  // Smart Library Widget
                  const Text('Biblioteca Inteligente',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildSmartLibraryCards(context),
                  const SizedBox(height: 24),

                  // Recent Additions Widget
                  const Text('Adicionados Recentemente',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildRecentsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildGreetingWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bem-vindo de volta!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Que tal continuar de onde parou?',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // Logic to resume last session could go here
              // For now we just pick a random track from recents
              if (_recentTracks.isNotEmpty) {
                _playTrack(_recentTracks.first);
              }
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Tocar Algo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartLibraryCards(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final cards = [
          _SmartCard(
            title: 'Top Hits',
            icon: Icons.trending_up,
            color: Colors.orange,
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => SmartLibraryView())),
          ),
          _SmartCard(
            title: 'Relax',
            icon: Icons.spa,
            color: Colors.teal,
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => MoodExplorerView())),
          ),
          _SmartCard(
            title: 'Stats',
            icon: Icons.bar_chart,
            color: Colors.deepPurple,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ListeningStatsView())),
          ),
        ];

        if (isNarrow) {
          return Column(
            children: cards
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: c,
                    ))
                .toList(),
          );
        }

        return Row(
          children: cards
              .map((c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: c,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildRecentsList() {
    if (_recentTracks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Nenhuma música recente.'),
      );
    }
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _recentTracks.length,
        itemBuilder: (context, index) {
          final track = _recentTracks[index];
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _playTrack(track),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(track['thumbnail'] ??
                              'https://via.placeholder.com/150'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    track['title'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    track['artist'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MoodsWidget extends StatelessWidget {
  const _MoodsWidget();

  @override
  Widget build(BuildContext context) {
    final moods = [
      {
        'label': 'Foco',
        'icon': Icons.center_focus_strong,
        'color': Colors.blue
      },
      {'label': 'Treino', 'icon': Icons.fitness_center, 'color': Colors.red},
      {'label': 'Festa', 'icon': Icons.celebration, 'color': Colors.purple},
      {'label': 'Viagem', 'icon': Icons.directions_car, 'color': Colors.green},
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: moods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final m = moods[index];
          return Column(
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => MoodExplorerView()));
                },
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (m['color'] as Color).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(m['icon'] as IconData, color: m['color'] as Color),
                ),
              ),
              const SizedBox(height: 8),
              Text(m['label'] as String, style: const TextStyle(fontSize: 12)),
            ],
          );
        },
      ),
    );
  }
}

class _SmartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SmartCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

