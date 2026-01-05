import 'package:sqflite/sqflite.dart';
import 'package:music_tag_editor/models/search_models.dart';
import 'package:music_tag_editor/services/database/database_repository.dart';

class TrackRepository extends DatabaseRepository {
  static const String _tracksTable = 'tracks';

  TrackRepository(super.getDatabase);

  Future<void> saveTrack(Map<String, dynamic> track) async {
    final database = await db;
    await database.insert(
      _tracksTable,
      track,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getTracks(
      {bool includeVault = false}) async {
    final database = await db;
    if (includeVault) {
      return await database.query(_tracksTable);
    }
    return await database.query(_tracksTable, where: 'is_vault = 0');
  }

  Future<Map<String, String?>> getDownloadedUrls() async {
    final database = await db;
    final results =
        await database.query(_tracksTable, columns: ['url', 'local_path']);
    return {
      for (var r in results) r['url'] as String: r['local_path'] as String?
    };
  }

  Future<void> toggleVault(String trackId, bool inVault) async {
    final database = await db;
    await database.update(
      _tracksTable,
      {'is_vault': inVault ? 1 : 0},
      where: 'id = ?',
      whereArgs: [trackId],
    );
  }

  Future<void> deleteTrack(String id) async {
    final database = await db;
    await database.delete(_tracksTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SearchResult>> getAllTracks() async {
    final tracksData = await getTracks(includeVault: true);
    final List<SearchResult> allResults = tracksData
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
              isDownloaded: (data['is_downloaded'] as int?) == 1,
            ))
        .toList();

    // Deduplicate by metadata (Title + Artist)
    final Map<String, SearchResult> uniqueMap = {};
    for (var track in allResults) {
      final key =
          '${SearchResult.toMatchKey(track.artist)}:${SearchResult.toMatchKey(track.title)}';

      final existing = uniqueMap[key];
      if (existing == null) {
        uniqueMap[key] = track;
      } else {
        bool shouldReplace = false;
        if (track.localPath != null && existing.localPath == null) {
          shouldReplace = true;
        } else if (track.isDownloaded && !existing.isDownloaded) {
          shouldReplace = true;
        } else if (track.isVault && !existing.isVault) {
          shouldReplace = true;
        }

        if (shouldReplace) {
          uniqueMap[key] = track;
        }
      }
    }

    return uniqueMap.values.toList();
  }

  Future<void> trackPlay(String trackId) async {
    final database = await db;
    await database.rawUpdate('''
      UPDATE $_tracksTable 
      SET play_count = play_count + 1, 
          last_played = ? 
      WHERE id = ?
    ''', [DateTime.now().millisecondsSinceEpoch, trackId]);
  }

  Future<void> updateMetadata(
      String id, String title, String artist, String album) async {
    final database = await db;
    await database.update(
      _tracksTable,
      {
        'title': title,
        'artist': artist,
        'album': album,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getMostPlayed({int limit = 20}) async {
    final database = await db;
    return await database.query(
      _tracksTable,
      orderBy: 'play_count DESC',
      limit: limit,
      where: 'play_count > 0',
    );
  }

  Future<List<Map<String, dynamic>>> getRecentlyPlayed({int limit = 20}) async {
    final database = await db;
    return await database.query(
      _tracksTable,
      orderBy: 'last_played DESC',
      limit: limit,
      where: 'last_played IS NOT NULL',
    );
  }

  Future<List<Map<String, dynamic>>> getPlayHistory() async {
    final database = await db;
    return await database.query(
      _tracksTable,
      where: 'play_count > 0',
      orderBy: 'last_played DESC',
      limit: 100,
    );
  }

  Future<List<Map<String, dynamic>>> getTracksByMood(
      List<String> genres) async {
    final database = await db;
    if (genres.isEmpty) return [];

    final placeholders = List.filled(genres.length, '?').join(',');
    return await database.query(
      _tracksTable,
      where: 'LOWER(genre) IN ($placeholders)',
      whereArgs: genres,
    );
  }
}
