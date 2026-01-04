import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart' as fluent;

enum LearningChoice {
  forThisArtist,
  forAll,
  justThisOnce,
}

class LearningDialog extends StatelessWidget {
  const LearningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _buildFluent(context);
    }
    return _buildMaterial(context);
  }

  Widget _buildFluent(BuildContext context) {
    return fluent.ContentDialog(
      title: const Text('Como devo aprender?'),
      content: const Text('Você editou as tags manualmente. Como devo aplicar essa correção no futuro?'),
      actions: [
        fluent.Button(
          onPressed: () => Navigator.of(context).pop(LearningChoice.forThisArtist),
          child: const Text('Para este artista'),
        ),
        fluent.Button(
          onPressed: () => Navigator.of(context).pop(LearningChoice.forAll),
          child: const Text('Para todos'),
        ),
        fluent.Button(
          onPressed: () => Navigator.of(context).pop(LearningChoice.justThisOnce),
          child: const Text('Só desta vez'),
        ),
      ],
    );
  }

  Widget _buildMaterial(BuildContext context) {
    return material.AlertDialog(
      title: const Text('How should I learn from this?'),
      content: const Text('You\'ve manually edited the tags. How should I apply this correction in the future?'),
      actions: [
        material.TextButton(
          onPressed: () => Navigator.of(context).pop(LearningChoice.forThisArtist),
          child: const Text('For this artist'),
        ),
        material.TextButton(
          onPressed: () => Navigator.of(context).pop(LearningChoice.forAll),
          child: const Text('For all tracks'),
        ),
        material.TextButton(
          onPressed: () => Navigator.of(context).pop(LearningChoice.justThisOnce),
          child: const Text('Just this once'),
        ),
      ],
    );
  }
}

