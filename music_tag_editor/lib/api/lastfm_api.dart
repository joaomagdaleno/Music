import 'package:http/http.dart' as http;
import 'dart:convert';

class LastFmApi {
  static const String _baseUrl = 'http://ws.audioscrobbler.com/2.0/';
  final http.Client _client;
  final String _apiKey;

  LastFmApi({http.Client? client, String apiKey = 'YOUR_LASTFM_API_KEY'})
      : _client = client ?? http.Client(),
        _apiKey = apiKey;

  Future<Map<String, dynamic>?> getTrackInfo(
      String title, String artist) async {
    if (_apiKey == 'YOUR_LASTFM_API_KEY') {
      return null;
    }

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
      // Log or handle error
    }
    return null;
  }
}
