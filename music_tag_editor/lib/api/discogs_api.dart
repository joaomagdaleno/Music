import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:music_tag_editor/utils/rate_limiter.dart';

/// Discogs API adapter for album art, labels, and release info.
class DiscogsApi {
  // Note: For production, use your own Discogs API key.
  // For now, we use the public search which has rate limits.
  static const String _baseUrl = 'https://api.discogs.com';
  static const String _userAgent = 'MusicTagEditor/1.0';

  final http.Client _client;
  final RateLimiter _rateLimiter;

  DiscogsApi({http.Client? client}) 
      : _client = client ?? DependencyManager.instance.client,
        _rateLimiter = RateLimiter(maxRequests: 20, interval: const Duration(minutes: 1));

  Future<Map<String, dynamic>?> searchRelease(
      String title, String artist) async {
    try {
      await _rateLimiter.wait();
      final query = Uri.encodeComponent('$artist $title');
      final url = Uri.parse('$_baseUrl/database/search?q=$query&type=release');

      final response = await _client.get(url, headers: {
        'User-Agent': _userAgent,
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];

        if (results.isNotEmpty) {
          final best = results.first;
          return {
            'title': best['title'],
            'year': best['year'],
            'label': (best['label'] as List?)?.firstOrNull,
            'genre': (best['genre'] as List?)?.firstOrNull,
            'style': (best['style'] as List?)?.firstOrNull,
            'thumbnail': best['thumb'],
            'cover': best['cover_image'],
          };
        }
      }
    } catch (e) {
      debugPrint('❌ DiscogsApi Error: $e');
    }
    return null;
  }
}
