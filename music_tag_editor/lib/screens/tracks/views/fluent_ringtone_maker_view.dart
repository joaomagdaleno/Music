import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import 'package:music_tag_editor/services/download_service.dart';

/// Fluent UI view for RingtoneMakerScreen - WinUI 3 styling
class FluentRingtoneMakerView extends StatelessWidget {
  final SearchResult track;
  final material.RangeValues currentRange;
  final Duration totalDuration;
  final bool isPlayingSegment;
  final VoidCallback onPlaySegment;
  final VoidCallback onSave;
  final void Function(material.RangeValues) onRangeChanged;
  final String Function(Duration) formatDuration;

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

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('Criador de Toques')),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCover(context),
            const SizedBox(height: 32),
            Text(track.title, style: FluentTheme.of(context).typography.title, textAlign: TextAlign.center),
            Text(track.artist, style: TextStyle(color: FluentTheme.of(context).inactiveColor), textAlign: TextAlign.center),
            const SizedBox(height: 48),
            _buildRangeControls(context),
            const SizedBox(height: 48),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(BuildContext context) {
    return Container(
      width: 200, height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: track.thumbnail != null
            ? Image.network(track.thumbnail!, fit: BoxFit.cover)
            : Container(color: FluentTheme.of(context).cardColor, child: const Icon(FluentIcons.music_note, size: 80)),
      ),
    );
  }

  Widget _buildRangeControls(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formatDuration(Duration(seconds: currentRange.start.toInt()))),
            Text('Duração: ${(currentRange.end - currentRange.start).toInt()}s'),
            Text(formatDuration(Duration(seconds: currentRange.end.toInt()))),
          ],
        ),
        const SizedBox(height: 8),
        material.Theme(
          data: material.ThemeData(primarySwatch: material.Colors.blue),
          child: material.RangeSlider(
            values: currentRange,
            min: 0,
            max: totalDuration.inSeconds.toDouble() > 0 ? totalDuration.inSeconds.toDouble() : 100,
            divisions: totalDuration.inSeconds > 0 ? totalDuration.inSeconds : 1,
            onChanged: onRangeChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(isPlayingSegment ? FluentIcons.pause : FluentIcons.play, size: 32),
          onPressed: onPlaySegment,
        ),
        const SizedBox(width: 32),
        FilledButton(
          onPressed: onSave,
          child: const Padding(padding: EdgeInsets.all(12), child: Text('Exportar Toque')),
        ),
      ],
    );
  }
}
