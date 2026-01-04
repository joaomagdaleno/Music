import 'package:fluent_ui/fluent_ui.dart';
import 'package:music_tag_editor/screens/library/mood_explorer_screen.dart';
import 'package:music_tag_editor/screens/library/smart_library_screen.dart';
import 'package:music_tag_editor/screens/stats/listening_stats_screen.dart';
import 'package:music_tag_editor/screens/disco/disco_mode_screen.dart';
import 'package:music_tag_editor/services/persona_service.dart';
import 'package:music_tag_editor/models/persona_model.dart';

class FluentHomeView extends StatelessWidget {
  final bool isLoading;
  final List<Map<String, dynamic>> recentTracks;
  final void Function(Map<String, dynamic>) onPlayTrack;

  const FluentHomeView({
    super.key,
    required this.isLoading,
    required this.recentTracks,
    required this.onPlayTrack,
  });

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Início'),
        leading: Navigator.canPop(context)
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: IconButton(
                  icon: const Icon(FluentIcons.back),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            : null,
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.auto_enhance_on),
              label: const Text('Modo Disco'),
              onPressed: () => Navigator.push(
                context,
                FluentPageRoute(builder: (_) => const DiscoModeScreen()),
              ),
            ),
          ],
        ),
      ),
      content: isLoading
          ? const Center(child: ProgressRing())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreetingWidget(context),
                  const SizedBox(height: 24),
                  Text('Minhas Personas',
                      style: FluentTheme.of(context).typography.subtitle),
                  const SizedBox(height: 12),
                  _buildPersonaWidgets(context),
                  const SizedBox(height: 24),
                  Text('Explore por Vibe',
                      style: FluentTheme.of(context).typography.subtitle),
                  const SizedBox(height: 12),
                  _buildMoodsWidget(context),
                  const SizedBox(height: 24),
                  Text('Biblioteca Inteligente',
                      style: FluentTheme.of(context).typography.subtitle),
                  const SizedBox(height: 12),
                  _buildSmartLibraryCards(context),
                  const SizedBox(height: 24),
                  Text('Adicionados Recentemente',
                      style: FluentTheme.of(context).typography.subtitle),
                  const SizedBox(height: 12),
                  _buildRecentsList(context),
                ],
              ),
            ),
    );
  }

  Widget _buildGreetingWidget(BuildContext context) {
    return Card(
      backgroundColor: FluentTheme.of(context).accentColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bem-vindo de volta!',
                    style: FluentTheme.of(context).typography.title,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Que tal continuar de onde parou?',
                    style: FluentTheme.of(context).typography.body,
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () {
                if (recentTracks.isNotEmpty) {
                  onPlayTrack(recentTracks.first);
                }
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(FluentIcons.play),
                  SizedBox(width: 8),
                  Text('Tocar Algo'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonaWidgets(BuildContext context) {
    final personas = [
      {
        'label': 'Bibliotecário',
        'desc': 'Organize sua música',
        'icon': FluentIcons.library,
        'persona': AppPersona.librarian,
        'color': Colors.blue
      },
      {
        'label': 'Anfitrião',
        'desc': 'Modo Festa e Karaoke',
        'icon': FluentIcons.party_leader,
        'persona': AppPersona.host,
        'color': Colors.purple
      },
      {
        'label': 'Artesão',
        'desc': 'Cofre e Ferramentas',
        'icon': FluentIcons.developer_tools,
        'persona': AppPersona.artisan,
        'color': Colors.orange
      },
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: personas.map((p) {
        return HoverButton(
          onPressed: () =>
              PersonaService.instance.setPersona(p['persona'] as AppPersona),
          builder: (context, states) {
            return Card(
              backgroundColor: states.isHovered
                  ? (p['color'] as AccentColor).withValues(alpha: 0.1)
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(p['icon'] as IconData,
                        color: p['color'] as AccentColor, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(p['label'] as String,
                            style:
                                FluentTheme.of(context).typography.bodyStrong),
                        Text(p['desc'] as String,
                            style: FluentTheme.of(context).typography.caption),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildMoodsWidget(BuildContext context) {
    final moods = [
      {'label': 'Foco', 'icon': FluentIcons.bullseye, 'color': Colors.blue},
      {'label': 'Treino', 'icon': FluentIcons.running, 'color': Colors.red},
      {'label': 'Festa', 'icon': FluentIcons.music_note, 'color': Colors.purple},
      {'label': 'Viagem', 'icon': FluentIcons.car, 'color': Colors.green},
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
              HoverButton(
                onPressed: () {
                  Navigator.push(context,
                      FluentPageRoute(builder: (_) => MoodExplorerScreen()));
                },
                builder: (context, states) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (m['color'] as AccentColor).withValues(alpha: states.isHovered ? 0.2 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(m['icon'] as IconData, color: m['color'] as AccentColor),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(m['label'] as String, style: FluentTheme.of(context).typography.caption),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSmartLibraryCards(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _FluentSmartCard(
          title: 'Top Hits',
          icon: FluentIcons.trending12,
          color: Colors.orange,
          onTap: () => Navigator.push(
              context, FluentPageRoute(builder: (_) => const SmartLibraryScreen())),
        ),
        _FluentSmartCard(
          title: 'Relax',
          icon: FluentIcons.heart,
          color: Colors.teal,
          onTap: () => Navigator.push(
              context, FluentPageRoute(builder: (_) => MoodExplorerScreen())),
        ),
        _FluentSmartCard(
          title: 'Stats',
          icon: FluentIcons.chart,
          color: Colors.purple,
          onTap: () => Navigator.push(context,
              FluentPageRoute(builder: (_) => const ListeningStatsScreen())),
        ),
      ],
    );
  }

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
            child: HoverButton(
              onPressed: () => onPlayTrack(track),
              builder: (context, states) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          track['thumbnail'] ?? 'https://via.placeholder.com/150',
                          fit: BoxFit.cover,
                          cacheWidth: 360, // ⚡ Bolt: Optimize memory (120px * 3x)
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[100],
                            child: const Icon(FluentIcons.music_note, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      track['title'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FluentTheme.of(context).typography.bodyStrong,
                    ),
                    Text(
                      track['artist'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: FluentTheme.of(context).typography.caption,
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _FluentSmartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final AccentColor color;
  final VoidCallback onTap;

  const _FluentSmartCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HoverButton(
      onPressed: onTap,
      builder: (context, states) {
        return Card(
          backgroundColor: states.isHovered ? color.withValues(alpha: 0.1) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
                Text(title, style: FluentTheme.of(context).typography.bodyStrong),
              ],
            ),
          ),
        );
      },
    );
  }
}
