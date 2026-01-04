import 'package:flutter/material.dart';

/// Material Design view for ListeningStatsScreen
class MaterialListeningStatsView extends StatelessWidget {
  final int totalMinutes;
  final List<Map<String, dynamic>> topArtists;
  final List<Map<String, dynamic>> topTracks;
  final bool isLoading;

  const MaterialListeningStatsView({
    super.key,
    required this.totalMinutes,
    required this.topArtists,
    required this.topTracks,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Estatísticas de Escuta')),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTimeCard(context),
                    const SizedBox(height: 24),
                    Text('Top Artistas',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    _buildList(context, topArtists, Icons.person),
                    const SizedBox(height: 24),
                    Text('Top Músicas',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    _buildList(context, topTracks, Icons.music_note),
                  ],
                ),
              ),
      );

  Widget _buildTimeCard(BuildContext context) {
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(Icons.timer,
                size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 24),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tempo Total', style: Theme.of(context).textTheme.bodyLarge),
              Text('${hours}h ${mins}min',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
      BuildContext context, List<Map<String, dynamic>> items, IconData icon) {
    if (items.isEmpty) return const Text('Nenhum dado disponível.');
    return Column(
        children: items
            .map((item) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                    leading: Icon(icon),
                    title: Text(item['name'] ?? 'Desconhecido'),
                    subtitle: Text('${item['count'] ?? 0} reproduções'))))
            .toList());
  }
}
