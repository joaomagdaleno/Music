import 'package:flutter/material.dart';
import 'package:music_hub/models/search_models.dart';

/// Material Design view for DiscoModeScreen
class MaterialDiscoModeView extends StatelessWidget {
  final SearchResult? currentTrack;
  final List<double> bars;
  final Color primaryColor;
  final VoidCallback onTap;

  const MaterialDiscoModeView({
    super.key,
    required this.currentTrack,
    required this.bars,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: onTap,
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
              primaryColor.withValues(alpha: 0.4),
              Colors.black,
            ],
            radius: 1.2,
          ),
        ),
      );

  Widget _buildVisualizer() => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: 200,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: bars
              .map((val) => Expanded(
                      child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: val * 180,
                    color: primaryColor,
                  )))
              .toList(),
        ),
      );

  Widget _buildAlbumArt() => Center(
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: primaryColor.withValues(alpha: 0.5), blurRadius: 30)
            ],
          ),
          child: ClipOval(
            child: currentTrack?.thumbnail != null
                ? Image.network(currentTrack!.thumbnail!,
                    fit: BoxFit.cover, cacheWidth: 600)
                : Container(
                    color: Colors.grey[900],
                    child: const Icon(Icons.music_note,
                        size: 80, color: Colors.white54)),
          ),
        ),
      );

  Widget _buildInfo() => Positioned(
        top: 80,
        left: 20,
        right: 20,
        child: Column(
          children: [
            Text(currentTrack?.title ?? 'No Track',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(currentTrack?.artist ?? '',
                style: const TextStyle(color: Colors.white70, fontSize: 18)),
          ],
        ),
      );

  Widget _buildCloseHint() => const Positioned(
      bottom: 220,
      left: 0,
      right: 0,
      child: Center(
          child: Text('Toque para sair',
              style: TextStyle(color: Colors.white38, fontSize: 14))));
}
