import 'database_service.dart';
import 'musicbrainz_api.dart';
import 'lastfm_api.dart';

class MetadataCleanupService {
  static final MetadataCleanupService instance =
      MetadataCleanupService._internal();
  MetadataCleanupService._internal();

  final _db = DatabaseService.instance;
  final _api = MusicBrainzApi();
  final _lastFm = LastFmApi();

  Future<int> cleanupLibrary() async {
    final tracks = await _db.getTracks();
    int cleanedCount = 0;

    for (var trackData in tracks) {
      bool modified = false;
      String title = trackData['title'];
      String artist = trackData['artist'] ?? '';
      String? genre = trackData['genre'];

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

      // 3. Genre Enrichment (if missing)
      if (genre == null || genre.isEmpty) {
        try {
          // Try MusicBrainz first
          final results = await _api.searchMetadata(title, artist);
          if (results.isNotEmpty) {
            final genres = results.first['genres'] as List? ?? [];
            if (genres.isNotEmpty) {
              genre = genres.first.toString();
              modified = true;
            }
          }

          // Fallback to Last.fm if still missing
          if (genre == null || genre.isEmpty) {
            final lastFmInfo = await _lastFm.getTrackInfo(title, artist);
            if (lastFmInfo != null) {
              final genres = lastFmInfo['genres'] as List? ?? [];
              if (genres.isNotEmpty) {
                genre = genres.first.toString();
                modified = true;
              }
            }
          }

          // Final fallback to generic Mix if absolutely nothing found but we tried
          if (genre == null || genre.isEmpty) {
            genre = 'Mix';
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
