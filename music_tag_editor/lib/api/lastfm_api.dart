import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:music_tag_editor/utils/rate_limiter.dart';
import 'package:music_tag_editor/config/api_keys.dart';

class LastFmApi {
  static const String _baseUrl = 'http://ws.audioscrobbler.com/2.0/';
  final http.Client _client;
  final String _apiKey;
  final RateLimiter _rateLimiter;

  LastFmApi({http.Client? client, String apiKey = ApiKeys.lastFmApiKey})
      : _client = client ?? DependencyManager.instance.client,
        _apiKey = apiKey,
        _rateLimiter = RateLimiter(maxRequests: 30, interval: const Duration(minutes: 1));

  Future<Map<String, dynamic>?> getTrackInfo(
      String title, String artist) async {
    if (_apiKey == 'YOUR_LASTFM_API_KEY') {
      debugPrint('⚠️ LastFmApi: API Key not configured.');
      return null;
    }

    await _rateLimiter.wait();

    final url = Uri.parse(
        '$_baseUrl?method=track.getInfo&api_key=$_apiKey&artist=${Uri.encodeComponent(artist)}&track=${Uri.encodeComponent(title)}&format=json');

    try {
      final response = await _client.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['track'] != null) {
          final track = data['track'];
          final toptags = track['toptags']?['tag'] as List? ?? [];
          final genres = toptags.map((t) => t['name'].toString()).toList();

          return {
            'title': track['name'],
            'artist': track['artist']?['name'],
            'album': track['album']?['title'],
            'genres': genres,
          };
        }
      }
    } catch (e) {
      debugPrint('❌ LastFmApi Error: $e');
    }
    return null;
  }
}
