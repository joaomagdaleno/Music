import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:music_hub/core/services/dependency_manager.dart';
import 'package:music_hub/utils/rate_limiter.dart';
import 'package:music_hub/config/api_keys.dart';

/// Genius API adapter for song metadata and plain lyrics.
class GeniusApi {
  // Note: Genius requires an access token for full API access.
  // For now, we use public search endpoint.
  static const String _baseUrl = 'https://api.genius.com';

  final http.Client _client;
  final RateLimiter _rateLimiter;

  GeniusApi({http.Client? client})
      : _client = client ?? DependencyManager.instance.client,
        _rateLimiter =
            RateLimiter(maxRequests: 20, interval: const Duration(minutes: 1));

  Future<Map<String, dynamic>?> searchSong(String title, String artist) async {
    try {
      await _rateLimiter.wait();
      // Genius public search (limited without token)
      final query = Uri.encodeComponent('$artist $title');
      final url = Uri.parse('$_baseUrl/search?q=$query');

      // Without access token, we can only get limited results
      // For full support, user would need to provide their own token
      final response = await _client.get(url, headers: {
        'User-Agent': 'MusicTagEditor/1.0',
        'Authorization': 'Bearer ${ApiKeys.geniusAccessToken}',
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
      debugPrint('❌ GeniusApi Error: $e');
    }
    return null;
  }
}
