import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:music_player/database_service.dart';
import 'package:music_player/settings_page.dart';
import 'package:music_player/learning_dialog.dart';

void main() {
  // Setup sqflite_ffi for testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('DatabaseService Tests', () {
    late DatabaseService dbService;

    setUp(() async {
      dbService = DatabaseService.instance;
      // We use an in-memory database for testing
      // However, DatabaseService uses a singleton and its own path.
      // We might need to adjust DatabaseService to allow for a custom path or a custom database instance.
    });

    // Note: DatabaseService uses a fixed path 'music_tag_editor.db'.
    // In a test environment, it's better to use ':memory:'.
    // For now, let's see if we can at least test settings.

    test('Save and Load Filename Format', () async {
      await dbService.saveFilenameFormat(FilenameFormat.titleArtist);
      final format = await dbService.loadFilenameFormat();
      expect(format, FilenameFormat.titleArtist);
    });

    test('Save and Load Crossfade Duration', () async {
      await dbService.saveCrossfadeDuration(10);
      final duration = await dbService.loadCrossfadeDuration();
      expect(duration, 10);
    });

    test('Save and Load Generic Setting', () async {
      await dbService.saveSetting('test_key', 'test_value');
      final value = await dbService.getSetting('test_key');
      expect(value, 'test_value');
    });

    test('Learning Rules CRUD', () async {
      final rule = LearningRule(
        artist: 'Test Artist',
        field: 'title',
        originalValue: 'Old Title',
        correctedValue: 'New Title',
        choice: LearningChoice.forThisArtist,
      );

      await dbService.saveLearningRule(rule);
      final rules = await dbService.getLearningRules();

      expect(
          rules.any((r) =>
              r.artist == 'Test Artist' && r.correctedValue == 'New Title'),
          isTrue);
    });
  });
}
