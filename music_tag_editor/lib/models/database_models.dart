import 'package:music_tag_editor/widgets/learning_dialog.dart';

/// Rule for learning metadata corrections.
class LearningRule {
  final String? artist;
  final String field;
  final String originalValue;
  final String correctedValue;
  final LearningChoice choice;

  LearningRule({
    this.artist,
    required this.field,
    required this.originalValue,
    required this.correctedValue,
    required this.choice,
  });
}
