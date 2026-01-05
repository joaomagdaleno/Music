import 'package:sqflite/sqflite.dart';
import 'package:music_tag_editor/models/filename_format.dart';
import 'package:music_tag_editor/services/database/database_repository.dart';

class SettingsRepository extends DatabaseRepository {
  static const String _settingsTable = 'settings';

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
    return false;
  }

  Future<void> saveAgeBypass(bool enabled) async {
    final database = await db;
    await database.insert(
      _settingsTable,
      {'key': 'age_bypass', 'value': enabled.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

}
