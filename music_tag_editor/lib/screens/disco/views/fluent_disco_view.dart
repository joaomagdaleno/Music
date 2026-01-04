import 'package:fluent_ui/fluent_ui.dart';
import 'package:music_tag_editor/services/download_service.dart';

/// Fluent UI view for DiscoModeScreen - WinUI 3 styling
class FluentDiscoModeView extends StatelessWidget {
  final SearchResult? currentTrack;
  final List<double> bars;
  final Color primaryColor;
  final VoidCallback onTap;

  const FluentDiscoModeView({
    super.key,
    required this.currentTrack,
    required this.bars,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.black,
          child: Stack(
            children: [
              _buildGlow(),
              _buildVisualizer(),
              _buildAlbumArt(),
              _buildInfo(),
              _buildCloseHint(),
            ],
          ),
        ),
      );

  Widget _buildGlow() => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              primaryColor.withValues(alpha: 0.3),
              Colors.purple.withValues(alpha: 0.1),
              Colors.black,
            ],
            radius: 1.5,
          ),
        ),
      );

  Widget _buildVisualizer() => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: 250,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: bars
              .map((val) => Expanded(
                      child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: val * 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [primaryColor, Colors.purple]),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                            color: primaryColor.withValues(alpha: 0.5),
                            blurRadius: 10)
                      ],
                    ),
                  )))
              .toList(),
        ),
      );

  Widget _buildAlbumArt() => Center(
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: primaryColor.withValues(alpha: 0.6),
                  blurRadius: 40,
                  spreadRadius: 10)
            ],
          ),
          child: ClipOval(
            child: currentTrack?.thumbnail != null
                ? Image.network(currentTrack!.thumbnail!,
                    fit: BoxFit.cover, cacheWidth: 600)
                : Container(
                    color: Colors.grey.withValues(alpha: 0.1),
                    child: const Icon(FluentIcons.music_note,
                        size: 100, color: Colors.white)),
          ),
        ),
      );

  Widget _buildInfo() => Positioned(
        top: 60,
        left: 40,
        right: 40,
        child: Column(
          children: [
            Text(currentTrack?.title ?? 'Silêncio...',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none)),
            const SizedBox(height: 12),
            Text(currentTrack?.artist ?? '',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 20,
                    decoration: TextDecoration.none)),
          ],
        ),
      );

  Widget _buildCloseHint() => Positioned(
      bottom: 260,
      left: 0,
      right: 0,
      child: Center(
          child: Text('Clique para sair',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.2),
                  fontSize: 14,
                  decoration: TextDecoration.none))));
}
