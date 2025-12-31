import 'package:flutter/material.dart';
import 'package:music_tag_editor/services/lyrics_service.dart';

/// Material Design view for KaraokeScreen
class MaterialKaraokeView extends StatelessWidget {
  final Map<String, dynamic> track;
  final List<LyricLine> lyrics;
  final int activeLineIndex;
  final ScrollController scrollController;
  final VoidCallback onResume;
  final VoidCallback onClose;

  const MaterialKaraokeView({
    super.key,
    required this.track,
    required this.lyrics,
    required this.activeLineIndex,
    required this.scrollController,
    required this.onResume,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildGlow(context),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildLyrics(context)),
                _buildControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlow(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.5),
          radius: 1.5,
          colors: [Theme.of(context).colorScheme.primary.withOpacity(0.3), Colors.black],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: onClose),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(track['title'] ?? 'Karaoke', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(track['artist'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
        ],
      ),
    );
  }

  Widget _buildLyrics(BuildContext context) {
    if (lyrics.isEmpty) return const Center(child: Text('Letras não sincronizadas...', style: TextStyle(color: Colors.white54)));
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 300, horizontal: 32),
      itemCount: lyrics.length,
      itemBuilder: (context, index) {
        final isActive = index == activeLineIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 80,
          alignment: Alignment.center,
          child: Text(
            lyrics[index].text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isActive ? 32 : 24,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.white : Colors.white38,
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: IconButton(iconSize: 48, icon: const Icon(Icons.play_circle_filled, color: Colors.white), onPressed: onResume),
    );
  }
}
