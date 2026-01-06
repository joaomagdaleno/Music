import 'package:sqflite/sqflite.dart';
import 'package:music_hub/features/library/models/filename_format.dart';
import 'package:music_hub/core/services/database/database_repository.dart';
import 'package:music_hub/features/library/models/database_models.dart';

import 'package:music_hub/features/library/models/learning_enums.dart';

class SettingsRepository extends DatabaseRepository {
  static const String _settingsTable = 'settings';
  static const String _foldersTable = 'music_folders';
  static const String _rulesTable = 'learning_rules';

  SettingsRepository(super.getDatabase);

  Future<void> saveFilenameFormat(FilenameFormat format) async {
    final database = await db;
    await database.insert(
      _settingsTable,
      {'key': 'filenameFormat', 'value': format.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<FilenameFormat> loadFilenameFormat() async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      _settingsTable,
      where: 'key = ?',
      whereArgs: ['filenameFormat'],
    );

    if (maps.isNotEmpty) {
      final value = maps.first['value'] as String;
      return FilenameFormat.values.firstWhere(
        (e) => e.toString() == value,
        orElse: () => FilenameFormat.artistTitle,
      );
    } else {
      return FilenameFormat.artistTitle;
    }
  }

  Future<int> loadCrossfadeDuration() async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      _settingsTable,
      where: 'key = ?',
      whereArgs: ['crossfadeDuration'],
    );
    if (maps.isNotEmpty) {
      return int.tryParse(maps.first['value'] as String) ?? 3;
    }
    return 3;
  }

  Future<void> saveCrossfadeDuration(int seconds) async {
    final database = await db;
    await database.insert(
      _settingsTable,
      {'key': 'crossfadeDuration', 'value': seconds.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      _settingsTable,
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<void> saveSetting(String key, String value) async {
    final database = await db;
    await database.insert(
      _settingsTable,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> loadAgeBypass() async {
    final database = await db;
    final result = await database.query(
      _settingsTable,
      where: 'key = ?',
      whereArgs: ['age_bypass'],
    );
    if (result.isNotEmpty) {
      return result.first['value'] == 'true';
    }
    return true;
  }

  Future<void> saveAgeBypass(bool enabled) async {
    final database = await db;
    await database.insert(
      _settingsTable,
      {'key': 'age_bypass', 'value': enabled.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Music Folders
  Future<void> addMusicFolder(String path) async {
    final database = await db;
    await database.insert(
      _foldersTable,
      {'path': path},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getMusicFolders() async {
    final database = await db;
    return await database.query(_foldersTable);
  }

  Future<void> removeMusicFolder(String path) async {
    final database = await db;
    await database.delete(
      _foldersTable,
      where: 'path = ?',
      whereArgs: [path],
    );
  }

  // Learning Rules
  Future<void> saveLearningRule(LearningRule rule) async {
    final database = await db;
    await database.insert(
      _rulesTable,
      {
        'artist': rule.artist,
        'field': rule.field,
        'originalValue': rule.originalValue,
        'correctedValue': rule.correctedValue,
        'choice': rule.choice.toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<LearningRule>> getLearningRules() async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(_rulesTable);
    return List.generate(
        maps.length,
        (i) => LearningRule(
              artist: maps[i]['artist'],
              field: maps[i]['field'],
              originalValue: maps[i]['originalValue'],
              correctedValue: maps[i]['correctedValue'],
              choice: LearningChoice.values.firstWhere(
                (e) => e.toString() == maps[i]['choice'],
                orElse: () => LearningChoice.justThisOnce,
              ),
            ));
  }

  // All Settings
  Future<Map<String, String>> getAllSettings() async {
    final database = await db;
    final List<Map<String, dynamic>> maps =
        await database.query(_settingsTable);
    return {for (var m in maps) m['key'] as String: m['value'] as String};
  }
}
