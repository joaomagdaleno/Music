import 'package:http/http.dart' as http;
import 'dart:convert';

class MusicBrainzApi {
  static const String _baseUrl = 'https://musicbrainz.org/ws/2/';

  Future<Map<String, dynamic>> searchRecording({
    required String artist,
    required String title,
  }) async {
    // Construct the query. We are looking for recordings.
    final query = 'artist:"$artist" AND recording:"$title"';
    final url = Uri.parse('${_baseUrl}recording?query=$query&fmt=json');

    final response = await http.get(
      url,
      // MusicBrainz API requires a User-Agent header.
      headers: {'User-Agent': 'MusicTagEditor/1.0.0 ( your-email@example.com )'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data from MusicBrainz API');
    }
  }
}
