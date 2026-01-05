import 'package:music_tag_editor/models/learning_enums.dart';

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

  bool matches(String original) => _normalize(original) == _normalize(originalValue);

  String _normalize(String s) => s.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
}
