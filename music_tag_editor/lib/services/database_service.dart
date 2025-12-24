import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';
import 'package:music_tag_editor/views/settings_page.dart'; // Import the enum
import 'package:music_tag_editor/widgets/learning_dialog.dart'; // Import the learning choice enum
import 'package:music_tag_editor/services/download_service.dart'; // For SearchResult and MediaPlatform

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
  static DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;

  @visibleForTesting
  static set instance(DatabaseService mock) => _instance = mock;

  @visibleForTesting
  static void resetInstance() => _instance = DatabaseService._internal();

  DatabaseService._internal();

  @visibleForTesting
  set db(Database base) => _database = base;

  @visibleForTesting
  Future<void> initForTesting(String path) async {
    _database = await _initDB(path: path);
  }

  static Database? _database;
  static const String _settingsTable = 'settings';
  static const String _rulesTable = 'learning_rules';
  static const String _tracksTable = 'tracks';
  static const String _playlistsTable = 'playlists';
  static const String _playlistTracksTable = 'playlist_tracks';
  static const String _duoGuestsTable = 'duo_guests';
  static const String _duoSessionsTable = 'duo_sessions';

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
      version: 6, // Incremented version for vault support
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
            is_downloaded INTEGER DEFAULT 0,
            genre TEXT,
            play_count INTEGER DEFAULT 0,
            last_played INTEGER,
            is_vault INTEGER DEFAULT 0
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
        await db.execute('''
          CREATE TABLE $_duoGuestsTable (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            last_connected INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE $_duoSessionsTable (
            guest_id TEXT,
            track_id TEXT,
            added_at INTEGER,
            PRIMARY KEY (guest_id, track_id),
            FOREIGN KEY (guest_id) REFERENCES $_duoGuestsTable (id) ON DELETE CASCADE,
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
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE $_tracksTable ADD COLUMN genre TEXT');
          await db.execute(
              'ALTER TABLE $_tracksTable ADD COLUMN play_count INTEGER DEFAULT 0');
          await db.execute(
              'ALTER TABLE $_tracksTable ADD COLUMN last_played INTEGER');
        }
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE $_duoGuestsTable (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              last_connected INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE $_duoSessionsTable (
              guest_id TEXT,
              track_id TEXT,
              added_at INTEGER,
              PRIMARY KEY (guest_id, track_id),
              FOREIGN KEY (guest_id) REFERENCES $_duoGuestsTable (id) ON DELETE CASCADE,
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

  Future<int> loadCrossfadeDuration() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
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
    final db = await database;
    await db.insert(
      _settingsTable,
      {'key': 'crossfadeDuration', 'value': seconds.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Generic setting methods for flexible key-value storage
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

  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      _settingsTable,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

  Future<List<Map<String, dynamic>>> getTracks(
      {bool includeVault = false}) async {
    final db = await database;
    if (includeVault) {
      return await db.query(_tracksTable);
    }
    return await db.query(_tracksTable, where: 'is_vault = 0');
  }

  Future<void> toggleVault(String trackId, bool inVault) async {
    final db = await database;
    await db.update(
      _tracksTable,
      {'is_vault': inVault ? 1 : 0},
      where: 'id = ?',
      whereArgs: [trackId],
    );
  }

  Future<void> deleteTrack(String id) async {
    final db = await database;
    await db.delete(_tracksTable, where: 'id = ?', whereArgs: [id]);
  }

  /// Get all tracks as SearchResult objects for use by services.
  Future<List<SearchResult>> getAllTracks() async {
    final tracksData = await getTracks(includeVault: true);
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
              isVault: (data['is_vault'] as int?) == 1,
            ))
        .toList();
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

  Future<void> trackPlay(String trackId) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE $_tracksTable 
      SET play_count = play_count + 1, 
          last_played = ? 
      WHERE id = ?
    ''', [DateTime.now().millisecondsSinceEpoch, trackId]);
  }

  Future<List<Map<String, dynamic>>> getMostPlayed({int limit = 20}) async {
    final db = await database;
    return await db.query(
      _tracksTable,
      orderBy: 'play_count DESC',
      limit: limit,
      where: 'play_count > 0',
    );
  }

  Future<List<Map<String, dynamic>>> getRecentlyPlayed({int limit = 20}) async {
    final db = await database;
    return await db.query(
      _tracksTable,
      orderBy: 'last_played DESC',
      limit: limit,
      where: 'last_played IS NOT NULL',
    );
  }

  // --- Duo Methods ---

  Future<void> saveGuest(String id, String name) async {
    final db = await database;
    await db.insert(
      _duoGuestsTable,
      {
        'id': id,
        'name': name,
        'last_connected': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getGuestHistory() async {
    final db = await database;
    return await db.query(_duoGuestsTable, orderBy: 'last_connected DESC');
  }

  Future<void> addTrackToDuoSession(String guestId, String trackId) async {
    final db = await database;
    await db.insert(
      _duoSessionsTable,
      {
        'guest_id': guestId,
        'track_id': trackId,
        'added_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getDuoSessionTracks(String guestId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT t.* FROM $_tracksTable t
      JOIN $_duoSessionsTable ds ON t.id = ds.track_id
      WHERE ds.guest_id = ?
      ORDER BY ds.added_at ASC
    ''', [guestId]);
  }

  // --- Mood Methods ---

  Future<List<Map<String, dynamic>>> getTracksByMood(String mood) async {
    final db = await database;
    List<String> genres = [];

    switch (mood.toLowerCase()) {
      case 'energético':
        genres = [
          'rock',
          'metal',
          'electronic',
          'dance',
          'pop',
          'punk',
          'hip hop'
        ];
        break;
      case 'relaxante':
        genres = [
          'classical',
          'jazz',
          'ambient',
          'acoustic',
          'lo-fi',
          'reggae'
        ];
        break;
      case 'foco':
        genres = ['instrumental', 'soundtrack', 'deep house', 'minimal'];
        break;
      case 'melancólico':
        genres = ['blues', 'soul', 'indie', 'folk', 'sad'];
        break;
    }

    if (genres.isEmpty) {
      return [];
    }

    final placeholders = List.filled(genres.length, '?').join(',');
    return await db.query(
      _tracksTable,
      where: 'LOWER(genre) IN ($placeholders)',
      whereArgs: genres,
    );
  }

  // --- Backup Support Methods ---

  Future<List<Map<String, dynamic>>> getPlayHistory() async {
    final db = await database;
    return await db.query(
      _tracksTable,
      where: 'play_count > 0',
      orderBy: 'last_played DESC',
      limit: 100,
    );
  }

  Future<Map<String, dynamic>> getAllSettings() async {
    final db = await database;
    final rows = await db.query(_settingsTable);
    final settings = <String, dynamic>{};
    for (var row in rows) {
      settings[row['key'] as String] = row['value'];
    }
    return settings;
  }

  Future<void> savePlaylist(Map<String, dynamic> playlist) async {
    final db = await database;
    await db.insert(
      _playlistsTable,
      {
        'name': playlist['name'],
        'description': playlist['description'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Age Restriction Bypass ---

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
