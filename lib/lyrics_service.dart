import 'dart:convert';
import 'package:http/http.dart' as http;

class LyricsService {
  static final LyricsService instance = LyricsService._internal();
  LyricsService._internal();

  Future<List<LyricLine>> fetchLyrics(String title, String artist) async {
    try {
      final url = Uri.parse(
          'https://lrclib.net/api/get?artist=${Uri.encodeComponent(artist)}&track=${Uri.encodeComponent(title)}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final lrc = data['syncedLyrics'] as String?;
        if (lrc != null) {
          return _parseLrc(lrc);
        }
      }
    } catch (e) {
      print("Error fetching lyrics: $e");
    }
    return [];
  }

  List<LyricLine> _parseLrc(String lrc) {
    final List<LyricLine> lines = [];
    final regExp = RegExp(r'\[(\d+):(\d+\.\d+)\](.*)');

    for (var line in lrc.split('\n')) {
      final match = regExp.firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = double.parse(match.group(2)!);
        final duration = Duration(
          minutes: minutes,
          seconds: seconds.toInt(),
          milliseconds: ((seconds - seconds.toInt()) * 1000).toInt(),
        );
        lines.add(LyricLine(time: duration, text: match.group(3)!.trim()));
      }
    }
    return lines;
  }
}

class LyricLine {
  final Duration time;
  final String text;

  LyricLine({required this.time, required this.text});
}
