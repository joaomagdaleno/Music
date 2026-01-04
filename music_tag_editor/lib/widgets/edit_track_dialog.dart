import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:music_tag_editor/models/music_track.dart';

class EditTrackDialog extends StatefulWidget {
  final MusicTrack track;

  const EditTrackDialog({super.key, required this.track});

  @override
  State<EditTrackDialog> createState() => _EditTrackDialogState();
}

class _EditTrackDialogState extends State<EditTrackDialog> {
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.track.title);
    _artistController = TextEditingController(text: widget.track.artist);
    _albumController = TextEditingController(text: widget.track.album);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  void _save() {
    final updatedTrack = MusicTrack(
      filePath: widget.track.filePath,
      title: _titleController.text,
      artist: _artistController.text,
      album: _albumController.text,
      trackNumber: widget.track.trackNumber,
    );
    Navigator.of(context).pop(updatedTrack);
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _buildFluent(context);
    }
    return _buildMaterial(context);
  }

  Widget _buildFluent(BuildContext context) {
    return fluent.ContentDialog(
      title: const Text('Editar Informações'),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            fluent.InfoLabel(label: 'Título', child: fluent.TextBox(controller: _titleController)),
            const SizedBox(height: 8),
            fluent.InfoLabel(label: 'Artista', child: fluent.TextBox(controller: _artistController)),
            const SizedBox(height: 8),
            fluent.InfoLabel(label: 'Álbum', child: fluent.TextBox(controller: _albumController)),
          ],
        ),
      ),
      actions: [
        fluent.Button(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        fluent.FilledButton(
          onPressed: _save,
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  Widget _buildMaterial(BuildContext context) {
    return material.AlertDialog(
      title: const Text('Edit Track Info'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            material.TextField(
              controller: _titleController,
              decoration: const material.InputDecoration(labelText: 'Title'),
            ),
            material.TextField(
              controller: _artistController,
              decoration: const material.InputDecoration(labelText: 'Artist'),
            ),
            material.TextField(
              controller: _albumController,
              decoration: const material.InputDecoration(labelText: 'Album'),
            ),
          ],
        ),
      ),
      actions: [
        material.TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        material.TextButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}


