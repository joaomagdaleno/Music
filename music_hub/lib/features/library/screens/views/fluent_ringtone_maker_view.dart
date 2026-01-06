import 'package:fluent_ui/fluent_ui.dart';
import 'package:music_hub/features/library/models/search_models.dart';
import 'package:flutter/material.dart' show RangeValues;

class FluentRingtoneMakerView extends StatelessWidget {
  const FluentRingtoneMakerView({
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
  Widget build(BuildContext context) => ScaffoldPage(
      header: PageHeader(
        title: Text('Criador de Toque: ${track.title}'),
        leading: IconButton(
          icon: const Icon(FluentIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(FluentIcons.music_note, size: 48),
            const SizedBox(height: 16),
            Text(track.artist, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 32),
            Text(
              '${formatDuration(Duration(seconds: currentRange.start.toInt()))} - ${formatDuration(Duration(seconds: currentRange.end.toInt()))}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Ajuste o intervalo (5s - 40s)'),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Button(
                  onPressed: onPlaySegment,
                  child: Row(
                    children: [
                      Icon(isPlayingSegment ? FluentIcons.pause : FluentIcons.play),
                      const SizedBox(width: 8),
                      Text(isPlayingSegment ? 'Pausar' : 'Ouvir Trecho'),
                    ],
                  ),
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
