import 'package:flutter/material.dart';
import 'package:music_hub/features/library/models/search_models.dart';

class MaterialRingtoneMakerView extends StatelessWidget {
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

  final SearchResult track;
  final RangeValues currentRange;
  final Duration totalDuration;
  final bool isPlayingSegment;
  final VoidCallback onPlaySegment;
  final VoidCallback onSave;
  final Function(RangeValues) onRangeChanged;
  final String Function(Duration) formatDuration;

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text('Criador de Toque: ${track.title}')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.music_note, size: 48),
            const SizedBox(height: 16),
            Text(track.artist, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 32),
            RangeSlider(
              values: currentRange,
              min: 0,
              max: totalDuration.inSeconds > 0 ? totalDuration.inSeconds.toDouble() : 30.0,
              onChanged: onRangeChanged,
            ),
            Text(
              '${formatDuration(Duration(seconds: currentRange.start.toInt()))} - ${formatDuration(Duration(seconds: currentRange.end.toInt()))}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: onPlaySegment,
                  icon: Icon(isPlayingSegment ? Icons.pause : Icons.play_arrow),
                  label: Text(isPlayingSegment ? 'Pausar' : 'Ouvir Trecho'),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: onSave,
                  child: const Text('Exportar Toque'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
}
