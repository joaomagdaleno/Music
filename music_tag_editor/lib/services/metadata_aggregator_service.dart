import 'dart:async';
import 'package:meta/meta.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:music_tag_editor/api/musicbrainz_api.dart';
import 'package:music_tag_editor/api/lastfm_api.dart';
import 'package:music_tag_editor/api/discogs_api.dart';
import 'package:music_tag_editor/api/genius_api.dart';
import 'package:music_tag_editor/api/netease_api.dart';
import 'package:music_tag_editor/services/lyrics_service.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:spotify/spotify.dart' as spot;

/// Unified result from metadata aggregation.
class AggregatedMetadata {
  final String? title;
  final String? artist;
  final String? album;
  final String? genre;
  final int? year;
  final String? thumbnail;
  final List<String> allGenres;
  final double confidence; // 0.0 to 1.0 based on source agreement

  AggregatedMetadata({
    this.title,
    this.artist,
    this.album,
    this.genre,
    this.year,
    this.thumbnail,
    this.allGenres = const [],
    this.confidence = 0.0,
  });
}

/// Multi-source metadata aggregator with voting and fallback logic.
class MetadataAggregatorService {
  static MetadataAggregatorService _instance =
      MetadataAggregatorService._internal();
  static MetadataAggregatorService get instance => _instance;

  @visibleForTesting
  static set instance(MetadataAggregatorService mock) => _instance = mock;
  MetadataAggregatorService._internal();

  MusicBrainzApi _musicBrainz = MusicBrainzApi();
  LastFmApi _lastFm = LastFmApi();
  DiscogsApi _discogs = DiscogsApi();
  GeniusApi _genius = GeniusApi();
  NeteaseApi _netease = NeteaseApi();
  LyricsService _lrcLib = LyricsService.instance;

  @visibleForTesting
  void setDependencies({
    MusicBrainzApi? musicBrainz,
    LastFmApi? lastFm,
    DiscogsApi? discogs,
    GeniusApi? genius,
    NeteaseApi? netease,
    LyricsService? lrcLib,
  }) {
    if (musicBrainz != null) _musicBrainz = musicBrainz;
    if (lastFm != null) _lastFm = lastFm;
    if (discogs != null) _discogs = discogs;
    if (genius != null) _genius = genius;
    if (netease != null) _netease = netease;
    if (lrcLib != null) _lrcLib = lrcLib;
  }

  /// Aggregate metadata from all sources with voting.
  Future<AggregatedMetadata> aggregateMetadata(
    String title,
    String artist, {
    int? durationMs,
  }) async {
    final results = <String, Map<String, dynamic>>{};

    // Query all sources in parallel
    // Query all sources in parallel with timeouts for speed
    await Future.wait([
      _fetchMusicBrainz(title, artist)
          .timeout(const Duration(seconds: 4), onTimeout: () => null)
          .then((r) => results['musicbrainz'] = r ?? {}),
      _fetchLastFm(title, artist)
          .timeout(const Duration(seconds: 3), onTimeout: () => null)
          .then((r) => results['lastfm'] = r ?? {}),
      _fetchDiscogs(title, artist)
          .timeout(const Duration(seconds: 3), onTimeout: () => null)
          .then((r) => results['discogs'] = r ?? {}),
      _fetchGenius(title, artist)
          .timeout(const Duration(seconds: 3), onTimeout: () => null)
          .then((r) => results['genius'] = r ?? {}),
      _fetchSpotify(title, artist)
          .timeout(const Duration(seconds: 3), onTimeout: () => null)
          .then((r) => results['spotify'] = r ?? {}),
    ]);

    // Apply voting logic
    return _vote(results, durationMs);
  }

  /// Fetch synced lyrics from multiple sources.
  Future<List<LyricLine>> fetchSyncedLyrics(
    String title,
    String artist, {
    int? durationMs,
  }) async {
    // Try LRCLib first (highest quality synced lyrics)
    var lyrics = await _lrcLib.fetchLyrics(title, artist);
    if (lyrics.isNotEmpty) {
      if (_validateDuration(lyrics, durationMs)) {
        return lyrics;
      }
    }

    // Fallback to NetEase (great for Asian music)
    lyrics = await _netease.fetchSyncedLyrics(title, artist);
    if (lyrics.isNotEmpty) {
      return lyrics;
    }

    // Return whatever we got, even if not duration-matched
    return await _lrcLib.fetchLyrics(title, artist);
  }

  /// Identify a track by its audio fingerprint using fpcalc + AcoustID.
  Future<AggregatedMetadata?> identifyByFingerprint(String filePath) async {
    try {
      final deps = DependencyManager.instance;

      // Generate fingerprint using fpcalc
      final result = await Process.run(
        deps.fpcalcPath,
        ['-json', filePath],
      );

      if (result.exitCode != 0) {
        return null;
      }

      final fpcalcData = json.decode(result.stdout as String);
      final fingerprint = fpcalcData['fingerprint'] as String?;
      final duration = fpcalcData['duration'] as num?;

      if (fingerprint == null || duration == null) {
        return null;
      }

      // Query AcoustID API
      // Note: For production, register at https://acoustid.org/ for an API key
      const acoustIdKey = 'YOUR_ACOUSTID_API_KEY'; // Replace with actual key
      final acoustIdUrl =
          Uri.parse('https://api.acoustid.org/v2/lookup?client=$acoustIdKey'
              '&meta=recordings+releasegroups+compress'
              '&duration=${duration.toInt()}'
              '&fingerprint=$fingerprint');

      final response = await http.get(acoustIdUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];

        if (results.isNotEmpty) {
          final best = results.first;
          final recordings = best['recordings'] as List? ?? [];

          if (recordings.isNotEmpty) {
            final recording = recordings.first;
            final artists = recording['artists'] as List? ?? [];
            final releaseGroups = recording['releasegroups'] as List? ?? [];

            return AggregatedMetadata(
              title: recording['title'],
              artist: artists.isNotEmpty ? artists.first['name'] : null,
              album: releaseGroups.isNotEmpty
                  ? releaseGroups.first['title']
                  : null,
              confidence: (best['score'] as num?)?.toDouble() ?? 0.0,
            );
          }
        }
      }
    } catch (e) {
      // Fingerprint identification failed, return null
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchMusicBrainz(
      String title, String artist) async {
    try {
      final results = await _musicBrainz.searchMetadata(title, artist);
      if (results.isNotEmpty) {
        final best = results.first;
        return {
          'title': best['title'],
          'artist': best['artist'],
          'album': best['album'],
          'genres': best['genres'] ?? [],
        };
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> _fetchLastFm(
      String title, String artist) async {
    try {
      final info = await _lastFm.getTrackInfo(title, artist);
      if (info != null) {
        return {
          'title': info['name'],
          'artist': info['artist'],
          'album': info['album'],
          'genres': info['genres'] ?? [],
        };
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> _fetchDiscogs(
      String title, String artist) async {
    try {
      final info = await _discogs.searchRelease(title, artist);
      if (info != null) {
        return {
          'title': info['title'],
          'year': info['year'],
          'genres': [info['genre'], info['style']].whereType<String>().toList(),
          'thumbnail': info['cover'],
        };
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> _fetchGenius(
      String title, String artist) async {
    try {
      final info = await _genius.searchSong(title, artist);
      if (info != null) {
        return {
          'title': info['title'],
          'artist': info['artist'],
          'thumbnail': info['thumbnail'],
        };
      }
    } catch (_) {}
    return null;
  }

  AggregatedMetadata _vote(
      Map<String, Map<String, dynamic>> results, int? durationMs) {
    // 1. Establish Source Hierarchy
    final mb = results['musicbrainz'] ?? {};
    final discogs = results['discogs'] ?? {};
    final lastfm = results['lastfm'] ?? {};
    final genius = results['genius'] ?? {};
    final spotify = results['spotify'] ?? {};

    // 2. Voting / Gap Filling Algorithm
    
    // Title/Artist: Trust MusicBrainz/Spotify first, otherwise vote
    String? finalTitle = mb['title'] ?? spotify['title'] ?? _getMostCommon([discogs['title'], lastfm['title'], genius['title']].whereType<String>().toList());
    String? finalArtist = mb['artist'] ?? spotify['artist'] ?? _getMostCommon([discogs['artist'], lastfm['artist'], genius['artist']].whereType<String>().toList());
    
    // Album: MusicBrainz > Spotify > Discogs > LastFM
    String? finalAlbum = mb['album'] ?? spotify['album'] ?? discogs['title'] ?? lastfm['album']; 
    
    // Year: Spotify/Discogs > MusicBrainz
    int? finalYear = spotify['year'] ?? (discogs['year'] != null ? int.tryParse(discogs['year'].toString()) : null);
    if (finalYear == null && mb['year'] != null) {
       finalYear = int.tryParse(mb['year'].toString());
    }

    // Fallback to voting for year if multiple sources have it
    if (finalYear == null) {
       final years = [lastfm['year'], discogs['year'], mb['year']].whereType<num>().map((e) => e.toInt()).toList();
       if (years.isNotEmpty) finalYear = years.first;
    }

    // Genre: Combine ALL unique genres found
    final Set<String> combinedGenres = {};
    for (var source in results.values) {
      if (source['genres'] is List) {
        combinedGenres.addAll((source['genres'] as List).map((e) => e.toString()));
      }
    }
    // Pick the most popular genre as primary
    String? finalGenre = _getMostCommon(combinedGenres.toList());

    // Thumbnail: Priority to high res: Spotify > Genius > Discogs
    String? finalThumbnail = spotify['thumbnail'] ?? genius['thumbnail'] ?? discogs['cover'] ?? discogs['thumbnail'] ?? lastfm['thumbnail'] ?? mb['thumbnail'];

    // Calculate confidence based on agreement
    int agreements = 0;
    int total = 0;
    
    final titleVotes = [mb['title'], discogs['title'], lastfm['title'], genius['title']].whereType<String>().toList();
    if (titleVotes.isNotEmpty) {
      total++;
       if (titleVotes.length > 1 || mb['title'] != null) agreements++;
    }

    final artistVotes = [mb['artist'], discogs['artist'], lastfm['artist'], genius['artist']].whereType<String>().toList();
    if (artistVotes.isNotEmpty) {
      total++;
      if (artistVotes.length > 1 || mb['artist'] != null) agreements++;
    }

    final confidence = total > 0 ? (agreements / total).clamp(0.0, 1.0) : 0.0;

    return AggregatedMetadata(
      title: finalTitle,
      artist: finalArtist,
      album: finalAlbum,
      genre: finalGenre,
      year: finalYear,
      thumbnail: finalThumbnail,
      allGenres: combinedGenres.toList(),
      confidence: confidence, 
    );
  }

  Future<Map<String, dynamic>?> _fetchSpotify(String title, String artist) async {
    try {
      final spotify = await SearchService.instance.spotifyApi;
      if (spotify == null) return null;

      final results = await spotify.search.get('$title $artist', types: [spot.SearchType.track]).first(1);
      if (results.isNotEmpty && results.first.items?.isNotEmpty == true) {
        final track = results.first.items!.first as spot.Track;
        return {
          'title': track.name,
          'artist': track.artists?.map((a) => a.name).join(', '),
          'album': track.album?.name,
          'year': track.album?.releaseDate != null ? int.tryParse(track.album!.releaseDate!.split('-')[0]) : null,
          'thumbnail': track.album?.images?.isNotEmpty == true ? track.album!.images!.first.url : null,
          'genres': [], 
        };
      }
    } catch (_) {}
    return null;
  }

  String? _getMostCommon(List<String> votes) {
    if (votes.isEmpty) {
      return null;
    }

    final counts = <String, int>{};
    for (var v in votes) {
      final normalized = v.toLowerCase();
      counts[normalized] = (counts[normalized] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Return original case from first occurrence
    final winner = sorted.first.key;
    return votes.firstWhere((v) => v.toLowerCase() == winner);
  }



  bool _validateDuration(List<LyricLine> lyrics, int? durationMs) {
    if (durationMs == null || lyrics.isEmpty) {
      return true;
    }

    final lastLine = lyrics.last;
    final lyricsEndMs = lastLine.time.inMilliseconds;

    // Allow 30 second tolerance
    return (lyricsEndMs - durationMs).abs() < 30000;
  }
}
