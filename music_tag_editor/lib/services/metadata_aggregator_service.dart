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
    await Future.wait([
      _fetchMusicBrainz(title, artist)
          .then((r) => results['musicbrainz'] = r ?? {}),
      _fetchLastFm(title, artist).then((r) => results['lastfm'] = r ?? {}),
      _fetchDiscogs(title, artist).then((r) => results['discogs'] = r ?? {}),
      _fetchGenius(title, artist).then((r) => results['genius'] = r ?? {}),
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
    // Collect all values for each field
    final titleVotes = <String>[];
    final artistVotes = <String>[];
    final albumVotes = <String>[];
    final genreVotes = <String>[];
    final yearVotes = <int>[];
    final thumbnails = <String>[];

    for (var source in results.values) {
      if (source['title'] != null) {
        titleVotes.add(source['title'].toString().trim());
      }
      if (source['artist'] != null) {
        artistVotes.add(source['artist'].toString().trim());
      }
      if (source['album'] != null) {
        albumVotes.add(source['album'].toString().trim());
      }
      if (source['year'] != null) {
        final y = int.tryParse(source['year'].toString());
        if (y != null) {
          yearVotes.add(y);
        }
      }
      if (source['thumbnail'] != null) {
        thumbnails.add(source['thumbnail'].toString());
      }

      final genres = source['genres'];
      if (genres is List) {
        for (var g in genres) {
          if (g != null) {
            genreVotes.add(g.toString());
          }
        }
      }
    }

    // Calculate confidence based on agreement
    int agreements = 0;
    int total = 0;

    if (titleVotes.isNotEmpty) {
      total++;
      if (_hasMajority(titleVotes)) agreements++;
    }
    if (artistVotes.isNotEmpty) {
      total++;
      if (_hasMajority(artistVotes)) agreements++;
    }

    final confidence = total > 0 ? agreements / total : 0.0;

    return AggregatedMetadata(
      title: _getMostCommon(titleVotes),
      artist: _getMostCommon(artistVotes),
      album: _getMostCommon(albumVotes),
      genre: _getMostCommon(genreVotes),
      year: yearVotes.isNotEmpty ? yearVotes.first : null,
      thumbnail: thumbnails.isNotEmpty ? thumbnails.first : null,
      allGenres: genreVotes.toSet().toList(),
      confidence: confidence,
    );
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

  bool _hasMajority(List<String> votes) {
    if (votes.length < 2) {
      return true;
    }

    final counts = <String, int>{};
    for (var v in votes) {
      final normalized = v.toLowerCase();
      counts[normalized] = (counts[normalized] ?? 0) + 1;
    }

    final max = counts.values.reduce((a, b) => a > b ? a : b);
    return max > votes.length / 2;
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
