/// Fast unit tests for LearningChoice enum
/// Tagged as @unit for quick execution (<5s timeout)
@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:music_tag_editor/widgets/learning_dialog.dart';

void main() {
  group('LearningChoice', () {
    test('has expected values', () {
      expect(LearningChoice.values.length, equals(3));
      expect(LearningChoice.forThisArtist, isNotNull);
      expect(LearningChoice.forAll, isNotNull);
      expect(LearningChoice.justThisOnce, isNotNull);
    });

    test('values have correct indices', () {
      expect(LearningChoice.forThisArtist.index, equals(0));
      expect(LearningChoice.forAll.index, equals(1));
      expect(LearningChoice.justThisOnce.index, equals(2));
    });

    test('values can be converted to string', () {
      expect(LearningChoice.forThisArtist.name, equals('forThisArtist'));
      expect(LearningChoice.forAll.name, equals('forAll'));
      expect(LearningChoice.justThisOnce.name, equals('justThisOnce'));
    });
  });
}
