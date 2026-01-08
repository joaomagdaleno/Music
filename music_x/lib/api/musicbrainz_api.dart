import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:music_hub/core/services/dependency_manager.dart';
import 'package:music_hub/utils/rate_limiter.dart';

class MusicBrainzApi {
  static const String _baseUrl = 'https://musicbrainz.org/ws/2/';

  final http.Client _client;
  final RateLimiter _rateLimiter;

  MusicBrainzApi({http.Client? client})
      : _client = client ?? DependencyManager.instance.client,
        _rateLimiter = RateLimiter(
            maxRequests: 1,
            interval: const Duration(seconds: 1)); // Strict 1 req/sec

  /// Escapes Lucene special characters in a query string.
  String _escapeLucene(String s) => s.replaceAllMapped(
        // Lucene special characters: + - && || ! ( ) { } [ ] ^ " ~ * ? : \ /
        RegExp(r'([+\-&|!(){}\[\]^"~*?:\\/])'),
        (m) => '\\${m.group(1)}',
      );

  Future<Map<String, dynamic>> searchRecording({
    required String artist,
    required String title,
  }) async {
    await _rateLimiter.wait();
    final safeArtist = _escapeLucene(artist);
    final safeTitle = _escapeLucene(title);
    final query = 'artist:"$safeArtist" AND recording:"$safeTitle"';
    final url = Uri.parse(
        '${_baseUrl}recording?query=${Uri.encodeComponent(query)}&fmt=json');

    final response = await _client.get(
      url,
      headers: {
        'User-Agent': 'MusicTagEditor/1.0.0 ( contact@musictageditor.app )'
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data from MusicBrainz API');
    }
  }

  Future<List<Map<String, dynamic>>> searchMetadata(
      String title, String artist) async {
    final results = await _executeSearch(title, artist);

    // Fallback: If no results with Artist + Title, try Title only
    if (results.isEmpty && artist.isNotEmpty) {
      return await _executeSearch(title, '');
    }

    return results;
  }

  Future<List<Map<String, dynamic>>> _executeSearch(
      String title, String artist) async {
    await _rateLimiter.wait();

    String query;
    if (artist.isNotEmpty) {
      final safeArtist = _escapeLucene(artist);
      final safeTitle = _escapeLucene(title);
      query = 'artist:"$safeArtist" AND recording:"$safeTitle"';
    } else {
      final safeTitle = _escapeLucene(title);
      query = 'recording:"$safeTitle"';
    }

    final url = Uri.parse(
        '${_baseUrl}recording?query=${Uri.encodeComponent(query)}&fmt=json');

    final response = await _client.get(
      url,
      headers: {
        'User-Agent': 'MusicTagEditor/1.0.0 ( contact@musictageditor.app )'
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final recordings = data['recordings'] as List? ?? [];

      return recordings.map((rec) {
        final tags = rec['tags'] as List? ?? [];
        final genres = tags.map((t) => t['name'].toString()).toList();

        // Robust artist parsing
        String artistName = '';
        final artistCredit = rec['artist-credit'] as List?;
        if (artistCredit != null) {
          final buffer = StringBuffer();
          for (final part in artistCredit) {
            if (part is Map) {
              buffer.write(part['name'] ?? '');
              buffer.write(part['joinphrase'] ?? '');
            }
          }
          artistName = buffer.toString();
        }

        return {
          'id': rec['id'],
          'title': rec['title'],
          'artist': artistName.isNotEmpty
              ? artistName
              : (rec['artist-credit']?[0]?['name'] ?? ''),
          'album': rec['releases']?[0]?['title'] ?? '',
          'genres': genres,
        };
      }).toList();
    } else {
      return [];
    }
  }
}
