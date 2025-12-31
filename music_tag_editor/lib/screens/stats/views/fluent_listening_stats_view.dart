import 'package:fluent_ui/fluent_ui.dart';

/// Fluent UI view for ListeningStatsScreen - WinUI 3 styling
class FluentListeningStatsView extends StatelessWidget {
  final int totalMinutes;
  final List<Map<String, dynamic>> topArtists;
  final List<Map<String, dynamic>> topTracks;
  final bool isLoading;

  const FluentListeningStatsView({
    super.key,
    required this.totalMinutes,
    required this.topArtists,
    required this.topTracks,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('Estatísticas de Escuta')),
      content: isLoading
          ? const Center(child: ProgressRing())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeCard(context),
                  const SizedBox(height: 24),
                  Text('Top Artistas', style: FluentTheme.of(context).typography.subtitle),
                  const SizedBox(height: 12),
                  _buildList(context, topArtists, FluentIcons.people),
                  const SizedBox(height: 24),
                  Text('Top Músicas', style: FluentTheme.of(context).typography.subtitle),
                  const SizedBox(height: 12),
                  _buildList(context, topTracks, FluentIcons.music_note),
                ],
              ),
            ),
    );
  }

  Widget _buildTimeCard(BuildContext context) {
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    return Card(
      padding: const EdgeInsets.all(24),
      backgroundColor: FluentTheme.of(context).accentColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(FluentIcons.timer, size: 48, color: FluentTheme.of(context).accentColor),
          const SizedBox(width: 24),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tempo Total', style: FluentTheme.of(context).typography.bodyLarge),
            Text('${hours}h ${mins}min', style: FluentTheme.of(context).typography.title),
          ]),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Map<String, dynamic>> items, IconData icon) {
    if (items.isEmpty) return const Text('Nenhum dado disponível.');
    return Column(children: items.map((item) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(leading: Icon(icon), title: Text(item['name'] ?? 'Desconhecido'), subtitle: Text('${item['count'] ?? 0} reproduções')))).toList());
  }
}
