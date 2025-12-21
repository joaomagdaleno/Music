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
  static const String _tracksTable = 'tracks';
  static const String _playlistsTable = 'playlists';
  static const String _playlistTracksTable = 'playlist_tracks';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'music_tag_editor.db');
    return await openDatabase(
      path,
      version: 3, // Incremented version for library/playlists
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
            stream_url TEXT,
            local_path TEXT,
            is_downloaded INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE $_playlistsTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE $_playlistTracksTable (
            playlist_id INTEGER,
            track_id TEXT,
            PRIMARY KEY (playlist_id, track_id),
            FOREIGN KEY (playlist_id) REFERENCES $_playlistsTable (id) ON DELETE CASCADE,
            FOREIGN KEY (track_id) REFERENCES $_tracksTable (id) ON DELETE CASCADE
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
        if (oldVersion < 3) {
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
              stream_url TEXT,
              local_path TEXT,
              is_downloaded INTEGER DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE $_playlistsTable (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              description TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE $_playlistTracksTable (
              playlist_id INTEGER,
              track_id TEXT,
              PRIMARY KEY (playlist_id, track_id),
              FOREIGN KEY (playlist_id) REFERENCES $_playlistsTable (id) ON DELETE CASCADE,
              FOREIGN KEY (track_id) REFERENCES $_tracksTable (id) ON DELETE CASCADE
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

  // --- Track Methods ---

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

  // --- Playlist Methods ---

  Future<int> createPlaylist(String name, {String? description}) async {
    final db = await database;
    return await db.insert(_playlistsTable, {
      'name': name,
      'description': description,
    });
  }

  Future<List<Map<String, dynamic>>> getPlaylists() async {
    final db = await database;
    return await db.query(_playlistsTable);
  }

  Future<void> addTrackToPlaylist(int playlistId, String trackId) async {
    final db = await database;
    await db.insert(_playlistTracksTable, {
      'playlist_id': playlistId,
      'track_id': trackId,
    });
  }

  Future<List<Map<String, dynamic>>> getPlaylistTracks(int playlistId) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT t.* FROM $_tracksTable t
      JOIN $_playlistTracksTable pt ON t.id = pt.track_id
      WHERE pt.playlist_id = ?
    ''', [playlistId]);
    return results;
  }
}
