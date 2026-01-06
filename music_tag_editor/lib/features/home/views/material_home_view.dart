import 'package:flutter/material.dart';
import 'package:music_hub/features/library/screens/mood_explorer_screen.dart';
import 'package:music_hub/features/library/screens/smart_library_screen.dart';
import 'package:music_hub/screens/stats/listening_stats_screen.dart';
import 'package:music_hub/features/party_mode/disco_mode_screen.dart';
import 'package:music_hub/services/persona_service.dart';
import 'package:music_hub/models/persona_model.dart';

class MaterialHomeView extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> recentTracks;
  final void Function(Map<String, dynamic>) onPlayTrack;

  const MaterialHomeView({
    super.key,
    required this.isLoading,
    required this.recentTracks,
    required this.onPlayTrack,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Início'),
          actions: [
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DiscoModeScreen()),
              ),
              tooltip: 'Modo Disco',
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreetingWidget(context),
                    const SizedBox(height: 32),
                    const Text('Minhas Personas',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildPersonaGrid(context),
                    const SizedBox(height: 32),
                    const Text('Explore por Vibe',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    const _MoodsWidget(),
                    const SizedBox(height: 24),
                    const Text('Biblioteca Inteligente',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildSmartLibraryCards(context),
                    const SizedBox(height: 24),
                    const Text('Adicionados Recentemente',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildRecentsList(context),
                  ],
                ),
              ),
      );

  Widget _buildGreetingWidget(BuildContext context) => Container(
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
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
                if (recentTracks.isNotEmpty) {
                  onPlayTrack(recentTracks.first);
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

  Widget _buildPersonaGrid(BuildContext context) {
    final personas = [
      {
        'label': 'Bibliotecário',
        'desc': 'Tags e Organização',
        'icon': Icons.library_books,
        'persona': AppPersona.librarian,
        'color': Colors.blue
      },
      {
        'label': 'Anfitrião',
        'desc': 'Festa e Karaoke',
        'icon': Icons.celebration,
        'persona': AppPersona.host,
        'color': Colors.purple
      },
      {
        'label': 'Artesão',
        'desc': 'Cofre e Utilidades',
        'icon': Icons.architecture,
        'persona': AppPersona.artisan,
        'color': Colors.orange
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 1,
      mainAxisSpacing: 12,
      childAspectRatio: 4,
      children: personas
          .map((p) => InkWell(
                onTap: () => PersonaService.instance
                    .setPersona(p['persona'] as AppPersona),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: (p['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (p['color'] as Color).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(p['icon'] as IconData,
                          color: p['color'] as Color, size: 32),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['label'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(p['desc'] as String,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildSmartLibraryCards(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          final cards = [
            _SmartCard(
              title: 'Top Hits',
              icon: Icons.trending_up,
              color: Colors.orange,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SmartLibraryScreen())),
            ),
            _SmartCard(
              title: 'Relax',
              icon: Icons.spa,
              color: Colors.teal,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MoodExplorerScreen())),
            ),
            _SmartCard(
              title: 'Stats',
              icon: Icons.bar_chart,
              color: Colors.deepPurple,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ListeningStatsScreen())),
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

  Widget _buildRecentsList(BuildContext context) {
    if (recentTracks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Nenhuma música recente.'),
      );
    }
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recentTracks.length,
        itemBuilder: (context, index) {
          final track = recentTracks[index];
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onPlayTrack(track),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        track['thumbnail'] ?? 'https://via.placeholder.com/150',
                        fit: BoxFit.cover,
                        cacheWidth: 360, // ⚡ Bolt: Optimize memory (120px * 3x)
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[900],
                          child: const Icon(Icons.music_note,
                              color: Colors.white54),
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
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MoodExplorerScreen()));
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
  Widget build(BuildContext context) => InkWell(
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
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      );
}
