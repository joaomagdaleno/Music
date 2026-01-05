import 'package:sqflite/sqflite.dart';
import 'package:music_tag_editor/services/database/database_repository.dart';

class PlaylistRepository extends DatabaseRepository {
  static const String _tracksTable = 'tracks';
  static const String _playlistsTable = 'playlists';
  static const String _playlistTracksTable = 'playlist_tracks';

  PlaylistRepository(super.getDatabase);

  Future<int> createPlaylist(String name, {String? description}) async {
    final database = await db;
    return await database.insert(_playlistsTable, {
      'name': name,
      'description': description,
    });
  }

  Future<List<Map<String, dynamic>>> getPlaylists() async {
    final database = await db;
    return await database.query(_playlistsTable);
  }

  Future<void> addTrackToPlaylist(int playlistId, String trackId) async {
    final database = await db;
    await database.insert(_playlistTracksTable, {
      'playlist_id': playlistId,
      'track_id': trackId,
    });
  }

  Future<List<Map<String, dynamic>>> getPlaylistTracks(int playlistId) async {
    final database = await db;
    final results = await database.rawQuery('''
      SELECT t.* FROM $_tracksTable t
      JOIN $_playlistTracksTable pt ON t.id = pt.track_id
      WHERE pt.playlist_id = ?
    ''', [playlistId]);
    return results;
  }

  Future<void> savePlaylist(Map<String, dynamic> playlist) async {
    final database = await db;
    await database.insert(
      _playlistsTable,
      {
        'name': playlist['name'],
        'description': playlist['description'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
