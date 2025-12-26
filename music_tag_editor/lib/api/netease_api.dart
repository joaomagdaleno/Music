import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:music_tag_editor/services/lyrics_service.dart';

/// NetEase Cloud Music API adapter for synced lyrics (excellent for Asian music).
class NeteaseApi {
  static const String _baseUrl = 'https://music.163.com/api';

  Future<List<LyricLine>> fetchSyncedLyrics(String title, String artist) async {
    try {
      // Search for the song first
      final searchUrl = Uri.parse(
          '$_baseUrl/search/get?s=${Uri.encodeComponent("$artist $title")}&type=1&limit=5');

      final searchResponse = await http.get(searchUrl, headers: {
        'Referer': 'https://music.163.com',
        'User-Agent': 'Mozilla/5.0',
      });

      if (searchResponse.statusCode == 200) {
        final searchData = json.decode(searchResponse.body);
        final songs = searchData['result']?['songs'] as List? ?? [];

        if (songs.isNotEmpty) {
          final songId = songs.first['id'];

          // Fetch lyrics for the song
          final lyricsUrl = Uri.parse('$_baseUrl/song/lyric?id=$songId&lv=1');
          final lyricsResponse = await http.get(lyricsUrl, headers: {
            'Referer': 'https://music.163.com',
            'User-Agent': 'Mozilla/5.0',
          });

          if (lyricsResponse.statusCode == 200) {
            final lyricsData = json.decode(lyricsResponse.body);
            final lrc = lyricsData['lrc']?['lyric'] as String?;

            if (lrc != null && lrc.isNotEmpty) {
              return _parseLrc(lrc);
            }
          }
        }
      }
    } catch (e) {
      // Silently fail
    }
    return [];
  }

  List<LyricLine> _parseLrc(String lrc) {
    final List<LyricLine> lines = [];
    final regExp = RegExp(r'\[(\d+):(\d+\.?\d*)\](.*)');

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
        final text = match.group(3)!.trim();
        if (text.isNotEmpty) {
          lines.add(LyricLine(time: duration, text: text));
        }
      }
    }
    return lines;
  }
}

