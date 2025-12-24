import 'dart:convert';
import 'package:http/http.dart' as http;

/// Genius API adapter for song metadata and plain lyrics.
class GeniusApi {
  // Note: Genius requires an access token for full API access.
  // For now, we use public search endpoint.
  static const String _baseUrl = 'https://api.genius.com';

  final http.Client _client;

  GeniusApi({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>?> searchSong(String title, String artist) async {
    try {
      // Genius public search (limited without token)
      final query = Uri.encodeComponent('$artist $title');
      final url = Uri.parse('$_baseUrl/search?q=$query');

      // Without access token, we can only get limited results
      // For full support, user would need to provide their own token
      final response = await _client.get(url, headers: {
        'User-Agent': 'MusicTagEditor/1.0',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final hits = data['response']?['hits'] as List? ?? [];

        if (hits.isNotEmpty) {
          final song = hits.first['result'];
          return {
            'id': song['id'],
            'title': song['title'],
            'artist': song['primary_artist']?['name'],
            'thumbnail': song['song_art_image_thumbnail_url'],
            'url': song['url'],
          };
        }
      }
    } catch (e) {
      // Silently fail
    }
    return null;
  }
}
