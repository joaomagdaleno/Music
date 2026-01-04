import 'package:flutter/material.dart';
import 'package:music_tag_editor/services/download_service.dart';

/// Material Design view for RingtoneMakerScreen
class MaterialRingtoneMakerView extends StatelessWidget {
  final SearchResult track;
  final RangeValues currentRange;
  final Duration totalDuration;
  final bool isPlayingSegment;
  final VoidCallback onPlaySegment;
  final VoidCallback onSave;
  final void Function(RangeValues) onRangeChanged;
  final String Function(Duration) formatDuration;

  const MaterialRingtoneMakerView({
    super.key,
    required this.track,
    required this.currentRange,
    required this.totalDuration,
    required this.isPlayingSegment,
    required this.onPlaySegment,
    required this.onSave,
    required this.onRangeChanged,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criador de Toques')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            track.thumbnail != null ? Image.network(track.thumbnail!, width: 150, cacheWidth: 450) : const Icon(Icons.music_note, size: 100),
            const SizedBox(height: 24),
            Text(track.title, style: Theme.of(context).textTheme.headlineSmall),
            Text(track.artist, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 48),
            RangeSlider(
              values: currentRange,
              min: 0,
              max: totalDuration.inSeconds.toDouble() > 0 ? totalDuration.inSeconds.toDouble() : 100,
              onChanged: onRangeChanged,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: Icon(isPlayingSegment ? Icons.pause : Icons.play_arrow), onPressed: onPlaySegment, iconSize: 48),
                const SizedBox(width: 24),
                ElevatedButton(onPressed: onSave, child: const Text('Salvar Toque')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
