import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:music_tag_editor/views/settings_page.dart';
import 'package:music_tag_editor/widgets/learning_dialog.dart';
import 'package:music_tag_editor/services/download_service.dart';

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

class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance =>
      _instance ??= DatabaseService._internal();

  @visibleForTesting
  static set instance(DatabaseService mock) => _instance = mock;

  @visibleForTesting
  static void resetInstance() {
    _instance = null;
    _database = null;
  }

  DatabaseService._internal();

  @visibleForTesting
  set db(Database base) => _database = base;

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  static Database? _database;
  static const String _settingsTable = 'settings';
  static const String _rulesTable = 'learning_rules';
  static const String _tracksTable = 'tracks';

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB({String? path}) async {
    path ??= join(await getDatabasesPath(), 'music_tag_editor.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_settingsTable (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE $_rulesTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            artist TEXT,
            field TEXT NOT NULL,
            originalValue TEXT NOT NULL,
            correctedValue TEXT NOT NULL,
            choice TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE $_tracksTable (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            artist TEXT,
            album TEXT,
            thumbnail TEXT,
            duration INTEGER,
            platform TEXT NOT NULL,
            url TEXT NOT NULL,
            local_path TEXT,
            is_downloaded INTEGER DEFAULT 0,
            genre TEXT
          )
        ''');
      },
    );
  }

  Future<void> saveFilenameFormat(FilenameFormat format) async {
    final db = await database;
    await db.insert(
      _settingsTable,
      {'key': 'filenameFormat', 'value': format.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<FilenameFormat> loadFilenameFormat() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
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

  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      _settingsTable,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _settingsTable,
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<void> saveLearningRule(LearningRule rule) async {
    final db = await database;
    await db.insert(
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
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_rulesTable);

    return List.generate(maps.length, (i) {
      return LearningRule(
        artist: maps[i]['artist'],
        field: maps[i]['field'],
        originalValue: maps[i]['originalValue'],
        correctedValue: maps[i]['correctedValue'],
        choice: LearningChoice.values.firstWhere(
          (e) => e.toString() == maps[i]['choice'],
          orElse: () => LearningChoice.justThisOnce,
        ),
      );
    });
  }

  Future<void> saveTrack(Map<String, dynamic> track) async {
    final db = await database;
    await db.insert(
      _tracksTable,
      track,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getTracks() async {
    final db = await database;
    return await db.query(_tracksTable);
  }

  Future<void> deleteTrack(String id) async {
    final db = await database;
    await db.delete(_tracksTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SearchResult>> getAllTracks() async {
    final tracksData = await getTracks();
    return tracksData
        .map((data) => SearchResult(
              id: data['id'],
              title: data['title'],
              artist: data['artist'] ?? '',
              album: data['album'],
              thumbnail: data['thumbnail'],
              duration: data['duration'],
              url: data['url'] ?? '',
              platform: MediaPlatform.values.firstWhere(
                (e) => e.toString() == data['platform'],
                orElse: () => MediaPlatform.unknown,
              ),
              localPath: data['local_path'],
              genre: data['genre'],
            ))
        .toList();
  }

  Future<bool> loadAgeBypass() async {
    final db = await database;
    final result = await db.query(
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
    final db = await database;
    await db.insert(
      _settingsTable,
      {'key': 'age_bypass', 'value': enabled.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
