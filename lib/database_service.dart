import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'settings_page.dart'; // Import the enum
import 'learning_dialog.dart'; // Import the learning choice enum

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
  static Database? _database;
  static const String _settingsTable = 'settings';
  static const String _rulesTable = 'learning_rules';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'music_tag_editor.db');
    return await openDatabase(
      path,
      version: 2, // Incremented version for migration
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
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
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
        }
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
}
