import 'package:flutter/material.dart';

class LyricsDialog extends StatelessWidget {
  final String lyrics;

  const LyricsDialog({super.key, required this.lyrics});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Lyrics'),
      content: SingleChildScrollView(
        child: Text(
          lyrics,
          style: const TextStyle(fontSize: 16.0),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
