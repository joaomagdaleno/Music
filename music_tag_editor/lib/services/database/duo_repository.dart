import 'package:sqflite/sqflite.dart';
import 'package:music_tag_editor/services/database/database_repository.dart';

class DuoRepository extends DatabaseRepository {
  static const String _tracksTable = 'tracks';
  static const String _duoGuestsTable = 'duo_guests';
  static const String _duoSessionsTable = 'duo_sessions';
  static const String _foldersTable = 'music_folders';

  DuoRepository(super.getDatabase);

  Future<void> saveGuest(String id, String name) async {
    final database = await db;
    await database.insert(
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
    final database = await db;
    return await database.query(_duoGuestsTable,
        orderBy: 'last_connected DESC');
  }

  Future<void> addTrackToDuoSession(String guestId, String trackId) async {
    final database = await db;
    await database.insert(
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
    final database = await db;
    return await database.rawQuery('''
      SELECT t.* FROM $_tracksTable t
      JOIN $_duoSessionsTable ds ON t.id = ds.track_id
      WHERE ds.guest_id = ?
      ORDER BY ds.added_at ASC
    ''', [guestId]);
  }

  Future<void> addMusicFolder(String path) async {
    final database = await db;
    await database.insert(
      _foldersTable,
      {'path': path, 'added_at': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Map<String, dynamic>>> getMusicFolders() async {
    final database = await db;
    return await database.query(_foldersTable, orderBy: 'added_at DESC');
  }

  Future<void> removeMusicFolder(String path) async {
    final database = await db;
    await database.delete(_foldersTable, where: 'path = ?', whereArgs: [path]);
  }
}
