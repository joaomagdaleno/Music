import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:music_tag_editor/models/filename_format.dart';
import 'package:music_tag_editor/models/database_models.dart';
import 'package:music_tag_editor/models/search_models.dart';
import 'package:music_tag_editor/services/database/settings_repository.dart';
import 'package:music_tag_editor/services/database/track_repository.dart';
import 'package:music_tag_editor/services/database/playlist_repository.dart';
import 'package:music_tag_editor/services/database/duo_repository.dart';

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

  @visibleForTesting
  Future<void> initForTesting(String path) async {
    _database = await _initDB(path: path);
  }

  DatabaseService._internal() {
    _settings = SettingsRepository(() => database);
    _tracks = TrackRepository(() => database);
    _playlists = PlaylistRepository(() => database);
    _duo = DuoRepository(() => database);
  }

  late final SettingsRepository _settings;
  late final TrackRepository _tracks;
  late final PlaylistRepository _playlists;
  late final DuoRepository _duo;

  SettingsRepository get settings => _settings;
  TrackRepository get tracks => _tracks;
  PlaylistRepository get playlists => _playlists;
  DuoRepository get duo => _duo;

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<void> saveTrack(Map<String, dynamic> track) =>
      _tracks.saveTrack(track);
  Future<List<Map<String, dynamic>>> getTracks({bool includeVault = false}) =>
      _tracks.getTracks(includeVault: includeVault);
  Future<List<SearchResult>> getAllTracks() => _tracks.getAllTracks();

  Future<void> updateTrackMetadata(
          String id, String title, String artist, String album) =>
      _tracks.updateMetadata(id, title, artist, album);

  Future<void> saveSetting(String key, String value) =>
      _settings.saveSetting(key, value);
  Future<String?> getSetting(String key) => _settings.getSetting(key);

  Future<void> savePlaylist(Map<String, dynamic> playlist) =>
      _playlists.savePlaylist(playlist);
  Future<List<Map<String, dynamic>>> getPlaylists() =>
      _playlists.getPlaylists();

  // Settings helpers
  Future<void> saveFilenameFormat(FilenameFormat format) =>
      _settings.saveFilenameFormat(format);
  Future<FilenameFormat> loadFilenameFormat() =>
      _settings.loadFilenameFormat();
  Future<int> loadCrossfadeDuration() => _settings.loadCrossfadeDuration();
  Future<void> saveCrossfadeDuration(int seconds) =>
      _settings.saveCrossfadeDuration(seconds);
  Future<bool> loadAgeBypass() => _settings.loadAgeBypass();
  Future<void> saveAgeBypass(bool enabled) =>
      _settings.saveAgeBypass(enabled);

  // Track helpers
  Future<Map<String, String?>> getDownloadedUrls() =>
      _tracks.getDownloadedUrls();
  Future<void> toggleVault(String trackId, bool inVault) =>
      _tracks.toggleVault(trackId, inVault);
  Future<void> deleteTrack(String id) => _tracks.deleteTrack(id);
  Future<void> trackPlay(String trackId) => _tracks.trackPlay(trackId);
  Future<List<Map<String, dynamic>>> getMostPlayed({int limit = 20}) =>
      _tracks.getMostPlayed(limit: limit);
  Future<List<Map<String, dynamic>>> getRecentlyPlayed({int limit = 20}) =>
      _tracks.getRecentlyPlayed(limit: limit);
  Future<List<Map<String, dynamic>>> getPlayHistory() =>
      _tracks.getPlayHistory();
  Future<List<Map<String, dynamic>>> getTracksByMood(String mood) =>
      _tracks.getTracksByMood([mood]);

  // Playlist helpers (to implement in repository)
  Future<void> createPlaylist(String name, {String? description}) =>
      _playlists.createPlaylist(name, description: description);
  Future<void> addTrackToPlaylist(int playlistId, String trackId) =>
      _playlists.addTrackToPlaylist(playlistId, trackId);
  Future<List<Map<String, dynamic>>> getPlaylistTracks(int playlistId) =>
      _playlists.getPlaylistTracks(playlistId);

  // Duo helpers (to implement in repository)
  Future<void> saveGuest(String id, String name) => _duo.saveGuest(id, name);
  Future<List<Map<String, dynamic>>> getGuestHistory() => _duo.getGuestHistory();
  Future<void> addTrackToDuoSession(String guestId, String trackId) =>
      _duo.addTrackToDuoSession(guestId, trackId);
  Future<List<Map<String, dynamic>>> getDuoSessionTracks(String guestId) =>
      _duo.getDuoSessionTracks(guestId);

  // Music Folders
  Future<void> addMusicFolder(String path) => _settings.addMusicFolder(path);
  Future<List<Map<String, dynamic>>> getMusicFolders() =>
      _settings.getMusicFolders();
  Future<void> removeMusicFolder(String path) =>
      _settings.removeMusicFolder(path);

  // Learning Rules
  Future<void> saveLearningRule(LearningRule rule) =>
      _settings.saveLearningRule(rule);
  Future<List<LearningRule>> getLearningRules() => _settings.getLearningRules();

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<Database> _initDB({String? path}) async {
    final dbPath = path ?? join(await getDatabasesPath(), 'music_player.db');
    return await openDatabase(
      dbPath,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tracks(
        id TEXT PRIMARY KEY,
        title TEXT,
        artist TEXT,
        album TEXT,
        thumbnail TEXT,
        duration INTEGER,
        url TEXT,
        platform TEXT,
        local_path TEXT,
        genre TEXT,
        is_vault INTEGER DEFAULT 0,
        is_downloaded INTEGER DEFAULT 0,
        is_official INTEGER DEFAULT 0,
        play_count INTEGER DEFAULT 0,
        last_played INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE settings(
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE playlists(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        description TEXT,
        created_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE playlist_tracks(
        playlist_id INTEGER,
        track_id TEXT,
        PRIMARY KEY(playlist_id, track_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE guests(
        id TEXT PRIMARY KEY,
        name TEXT,
        last_connected INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE duo_shared_tracks(
        guest_id TEXT,
        track_id TEXT,
        PRIMARY KEY(guest_id, track_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE music_folders(
        path TEXT PRIMARY KEY
      )
    ''');

    await db.execute('''
      CREATE TABLE learning_rules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pattern TEXT,
        replacement TEXT,
        is_regex INTEGER,
        priority INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE tracks ADD COLUMN genre TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE tracks ADD COLUMN is_vault INTEGER DEFAULT 0');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE tracks ADD COLUMN is_downloaded INTEGER DEFAULT 0');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE tracks ADD COLUMN is_official INTEGER DEFAULT 0');
    }
  }

  Future<Map<String, dynamic>> getAllSettings() => _settings.getAllSettings();
}
