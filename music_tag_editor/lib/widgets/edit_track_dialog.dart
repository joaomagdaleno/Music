import 'package:flutter/material.dart';
import 'main.dart'; // To get MusicTrack class

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Track Info'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _artistController,
              decoration: const InputDecoration(labelText: 'Artist'),
            ),
            TextField(
              controller: _albumController,
              decoration: const InputDecoration(labelText: 'Album'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Return the updated track info
            final updatedTrack = MusicTrack(
              filePath: widget.track.filePath,
              title: _titleController.text,
              artist: _artistController.text,
              album: _albumController.text,
              trackNumber: widget.track.trackNumber,
            );
            Navigator.of(context).pop(updatedTrack);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
