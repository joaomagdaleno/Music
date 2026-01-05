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

import 'package:music_tag_editor/models/metadata_models.dart';

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

  Future<AggregatedMetadata> aggregateMetadata(
    String title,
    String artist, {
    int? durationMs,
  }) async {
    final results = <String, Map<String, dynamic>>{};

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
    ]);

    // Apply voting logic
    return _vote(results, title, artist, durationMs);
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

  AggregatedMetadata _vote(Map<String, Map<String, dynamic>> results,
      String title, String artist, int? durationMs) {
    // 1. Establish Source Hierarchy
    final mb = results['musicbrainz'] ?? {};
    final discogs = results['discogs'] ?? {};
    final lastfm = results['lastfm'] ?? {};
    final genius = results['genius'] ?? {};

    // 2. Voting / Gap Filling Algorithm

    // Sensitivity check: If a source has a wildly different artist, we ignore its title/artist votes
    // but might still keep its other data if confidence is high.
    bool sourceMatches(Map<String, dynamic> source) {
      if (source['artist'] == null || artist.isEmpty) return true;
      final sArtist = source['artist'].toString().toLowerCase();
      final targetArtist = artist.toLowerCase();

      // Simple inclusion or overlap check
      return sArtist.contains(targetArtist) || targetArtist.contains(sArtist);
    }

    final mbMatch = sourceMatches(mb);
    final discogsMatch = sourceMatches(discogs);
    final lastfmMatch = sourceMatches(lastfm);
    final geniusMatch = sourceMatches(genius);

    // Title/Artist: Trust MusicBrainz first (if it matches the intended artist), otherwise vote
    String? finalTitle = (mbMatch ? mb['title'] : null) ??
        _getMostCommon([
          if (discogsMatch) discogs['title'],
          if (lastfmMatch) lastfm['title'],
          if (geniusMatch) genius['title']
        ].whereType<String>().toList());

    String? finalArtist = (mbMatch ? mb['artist'] : null) ??
        _getMostCommon([
          if (discogsMatch) discogs['artist'],
          if (lastfmMatch) lastfm['artist'],
          if (geniusMatch) genius['artist']
        ].whereType<String>().toList());

    // Fallback to initial if nothing matched reasonably
    finalTitle ??= title;
    finalArtist ??= artist;

    final String? finalAlbum =
        mb['album'] ?? discogs['title'] ?? lastfm['album'];

    int? finalYear = (discogs['year'] != null
            ? int.tryParse(discogs['year'].toString())
            : null);
    if (finalYear == null && mb['year'] != null) {
      finalYear = int.tryParse(mb['year'].toString());
    }

    // Fallback to voting for year if multiple sources have it
    if (finalYear == null) {
      final years = [lastfm['year'], discogs['year'], mb['year']]
          .whereType<num>()
          .map((e) => e.toInt())
          .toList();
      if (years.isNotEmpty) finalYear = years.first;
    }

    // Genre: Combine ALL unique genres found
    final Set<String> combinedGenres = {};
    for (var source in results.values) {
      if (source['genres'] is List) {
        combinedGenres
            .addAll((source['genres'] as List).map((e) => e.toString()));
      }
    }
    // Pick the most popular genre as primary
    final String? finalGenre = _getMostCommon(combinedGenres.toList());

    final String? finalThumbnail = genius['thumbnail'] ??
        discogs['cover'] ??
        discogs['thumbnail'] ??
        lastfm['thumbnail'] ??
        mb['thumbnail'];

    // Calculate confidence based on agreement
    int agreements = 0;
    int total = 0;

    final titleVotes = [
      mb['title'],
      discogs['title'],
      lastfm['title'],
      genius['title']
    ].whereType<String>().toList();
    if (titleVotes.isNotEmpty) {
      total++;
      if (titleVotes.length > 1 || mb['title'] != null) agreements++;
    }

    final artistVotes = [
      mb['artist'],
      discogs['artist'],
      lastfm['artist'],
      genius['artist']
    ].whereType<String>().toList();
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
