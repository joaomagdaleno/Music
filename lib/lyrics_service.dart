import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

class LyricsService {
  static LyricsService _instance = LyricsService._internal();
  static LyricsService get instance => _instance;

  @visibleForTesting
  static set instance(LyricsService mock) => _instance = mock;

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
      debugPrint("Error fetching lyrics: $e");
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
