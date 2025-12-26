import 'package:flutter/material.dart';

enum LearningChoice {
  forThisArtist,
  forAll,
  justThisOnce,
}

class LearningDialog extends StatelessWidget {
  const LearningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('How should I learn from this?'),
      content: const Text('You\'ve manually edited the tags. How should I apply this correction in the future?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(LearningChoice.forThisArtist),
          child: const Text('For this artist'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(LearningChoice.forAll),
          child: const Text('For all tracks'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(LearningChoice.justThisOnce),
          child: const Text('Just this once'),
        ),
      ],
    );
  }
}
