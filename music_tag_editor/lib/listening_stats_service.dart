import 'database_service.dart';

class ListeningStats {
  final int totalTracks;
  final int totalPlays;
  final Duration estimatedListeningTime;
  final List<Map<String, dynamic>> topTracks;
  final List<MapEntry<String, int>> topArtists;
  final List<MapEntry<String, int>> topGenres;

  ListeningStats({
    required this.totalTracks,
    required this.totalPlays,
    required this.estimatedListeningTime,
    required this.topTracks,
    required this.topArtists,
    required this.topGenres,
  });
}

class ListeningStatsService {
  static final ListeningStatsService instance =
      ListeningStatsService._internal();
  ListeningStatsService._internal();

  final DatabaseService _db = DatabaseService.instance;

  Future<ListeningStats> getStats() async {
    final tracks = await _db.getTracks();

    // Calculate totals
    int totalPlays = 0;
    int totalDuration = 0;
    final Map<String, int> artistCounts = {};
    final Map<String, int> genreCounts = {};

    for (final track in tracks) {
      final playCount = (track['play_count'] as int?) ?? 0;
      final duration = (track['duration'] as int?) ?? 180; // Default 3 min
      final artist = track['artist'] as String? ?? 'Unknown';
      final genre = track['genre'] as String? ?? 'Unknown';

      totalPlays += playCount;
      totalDuration += duration * playCount;

      artistCounts[artist] = (artistCounts[artist] ?? 0) + playCount;
      if (genre != 'Unknown' && genre.isNotEmpty) {
        genreCounts[genre] = (genreCounts[genre] ?? 0) + playCount;
      }
    }

    // Sort tracks by play count
    final sortedTracks = List<Map<String, dynamic>>.from(tracks);
    sortedTracks.sort((a, b) => ((b['play_count'] as int?) ?? 0)
        .compareTo((a['play_count'] as int?) ?? 0));

    // Get top 5 tracks
    final topTracks = sortedTracks.take(5).toList();

    // Sort artists by play count
    final sortedArtists = artistCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topArtists = sortedArtists.take(5).toList();

    // Sort genres by play count
    final sortedGenres = genreCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topGenres = sortedGenres.take(5).toList();

    return ListeningStats(
      totalTracks: tracks.length,
      totalPlays: totalPlays,
      estimatedListeningTime: Duration(seconds: totalDuration),
      topTracks: topTracks,
      topArtists: topArtists,
      topGenres: topGenres,
    );
  }
}
