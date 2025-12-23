import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/views/settings_page.dart'; // For FilenameFormat
import 'package:music_tag_editor/widgets/learning_dialog.dart'; // For LearningChoice

void main() {
  group('DatabaseService', () {
    test('instance is accessible', () {
      expect(DatabaseService.instance, isNotNull);
    });
  });

  group('FilenameFormat', () {
    test('generateFilename returns string', () {
      const format = FilenameFormat.artistTitle;
      final filename = format.generateFilename(
        artist: 'Artist',
        title: 'Title',
        trackNumber: 1,
      );
      expect(filename, isA<String>());
      expect(filename, equals('Artist - Title'));
    });

    test('generateFilename handles titleArtist', () {
      const format = FilenameFormat.titleArtist;
      final filename = format.generateFilename(
        artist: 'Artist',
        title: 'Title',
        trackNumber: 1,
      );
      expect(filename, equals('Title (Artist)'));
    });
  });

  group('LearningChoice', () {
    test('has expected values', () {
      expect(LearningChoice.values, contains(LearningChoice.justThisOnce));
      expect(LearningChoice.values, contains(LearningChoice.forThisArtist));
      expect(LearningChoice.values, contains(LearningChoice.forAll));
    });
  });
}
