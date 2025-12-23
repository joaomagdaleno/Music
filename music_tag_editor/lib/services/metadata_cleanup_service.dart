import 'package:meta/meta.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/metadata_aggregator_service.dart';

class MetadataCleanupService {
  static MetadataCleanupService _instance = MetadataCleanupService._internal();
  static MetadataCleanupService get instance => _instance;

  @visibleForTesting
  static set instance(MetadataCleanupService mock) => _instance = mock;

  MetadataCleanupService._internal();

  final _db = DatabaseService.instance;
  final _aggregator = MetadataAggregatorService.instance;

  Future<int> cleanupLibrary() async {
    final tracks = await _db.getTracks();
    int cleanedCount = 0;

    for (var trackData in tracks) {
      bool modified = false;
      String title = trackData['title'];
      String artist = trackData['artist'] ?? '';
      String? genre = trackData['genre'];
      String? album = trackData['album'];
      String? thumbnail = trackData['thumbnail'];

      // 1. Title Cleanup
      final cleanTitle = _cleanString(title);
      if (cleanTitle != title) {
        title = cleanTitle;
        modified = true;
      }

      // 2. Artist Cleanup
      final cleanArtist = _cleanString(artist);
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
        final newTrack = Map<String, dynamic>.from(trackData);
        newTrack['title'] = title;
        newTrack['artist'] = artist;
        newTrack['genre'] = genre;
        newTrack['album'] = album;
        newTrack['thumbnail'] = thumbnail;
        await _db.saveTrack(newTrack);
        cleanedCount++;
      }
    }

    return cleanedCount;
  }

  String _cleanString(String input) {
    String output = input;
    final removals = [
      RegExp(r'\[.*?\]'), // Remove [anything]
      RegExp(r'\(.*?\)'), // Remove (anything)
      'OFFICIAL VIDEO',
      'Official Audio',
      'HD',
      '4K',
      'Lyric Video',
      'Lyrics',
      '#',
    ];

    for (var rem in removals) {
      if (rem is RegExp) {
        output = output.replaceAll(rem, '');
      } else {
        output = output.replaceAll(rem as String, '');
      }
    }

    return output.trim();
  }
}

