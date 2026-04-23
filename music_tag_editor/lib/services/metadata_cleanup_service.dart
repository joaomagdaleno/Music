import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/metadata_aggregator_service.dart';
import 'package:music_tag_editor/src/rust/api/cleanup.dart' as rust;

class MetadataCleanupService {
  static final MetadataCleanupService _instance = MetadataCleanupService._internal();
  static MetadataCleanupService get instance => _instance;

  MetadataCleanupService._internal();

  DatabaseService get _db => DatabaseService.instance;
  MetadataAggregatorService get _aggregator =>
      MetadataAggregatorService.instance;

  Future<int> cleanupLibrary() async {
    final tracks = await _db.getAllTracks();
    int cleanedCount = 0;

    for (var track in tracks) {
      bool modified = false;
      String title = track.title;
      String artist = track.artist;
      String? genre = track.genre;
      String? album = track.album;
      String? thumbnail = track.thumbnail;

      // 1. Title Cleanup via Rust Regex
      final cleanTitle = await rust.cleanTag(text: title);
      if (cleanTitle != title) {
        title = cleanTitle;
        modified = true;
      }

      // 2. Artist Cleanup via Rust Regex
      final cleanArtist = await rust.cleanTag(text: artist);
      if (cleanArtist != artist) {
        artist = cleanArtist;
        modified = true;
      }

      // 3. Use Aggregator for missing metadata
      if (genre == null || genre.isEmpty || album == null || album.isEmpty) {
        try {
          final metadata = await _aggregator.aggregateMetadata(title, artist);

          if ((genre == null || genre.isEmpty) && metadata.genre != null) {
            genre = metadata.genre;
            modified = true;
          }

          if ((album == null || album.isEmpty) && metadata.album != null) {
            album = metadata.album;
            modified = true;
          }

          if (thumbnail == null && metadata.thumbnail != null) {
            thumbnail = metadata.thumbnail;
            modified = true;
          }
        } catch (e) {
          // Ignore API errors for cleanup
        }
      }

      if (modified) {
        // Update track with cleaned metadata
        // Note: Assuming SearchResult has a way to update or we use _db directly
        await _db.saveTrack({
          'id': track.id,
          'title': title,
          'artist': artist,
          'genre': genre,
          'album': album,
          'thumbnail': thumbnail,
          'localPath': track.localPath,
        });
        cleanedCount++;
      }
    }

    return cleanedCount;
  }
}
