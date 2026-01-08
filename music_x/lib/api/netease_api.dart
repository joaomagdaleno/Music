import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:music_hub/core/services/dependency_manager.dart';
import 'package:music_hub/features/player/services/lyrics_service.dart';
import 'package:music_hub/utils/rate_limiter.dart';

/// NetEase Cloud Music API adapter for synced lyrics (excellent for Asian music).
class NeteaseApi {
  static const String _baseUrl = 'https://music.163.com/api';

  final http.Client _client;
  final RateLimiter _rateLimiter;

  NeteaseApi({http.Client? client})
      : _client = client ?? DependencyManager.instance.client,
        _rateLimiter =
            RateLimiter(maxRequests: 20, interval: const Duration(minutes: 1));

  Future<List<LyricLine>> fetchSyncedLyrics(String title, String artist) async {
    if (title.isEmpty || artist.isEmpty) return [];
    try {
      // Search for the song first
      await _rateLimiter.wait();
      final searchUrl = Uri.parse(
          '$_baseUrl/search/get?s=${Uri.encodeComponent("$artist $title")}&type=1&limit=5');

      final searchResponse = await _client.get(searchUrl, headers: {
        'Referer': 'https://music.163.com',
        'User-Agent': 'Mozilla/5.0',
      });

      if (searchResponse.statusCode == 200) {
        final searchData = json.decode(searchResponse.body);
        final songs = searchData['result']?['songs'] as List? ?? [];

        if (songs.isNotEmpty) {
          final songId = songs.first['id'];

          // Fetch lyrics for the song
          await _rateLimiter.wait();
          final lyricsUrl = Uri.parse('$_baseUrl/song/lyric?id=$songId&lv=1');
          final lyricsResponse = await _client.get(lyricsUrl, headers: {
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
      debugPrint('❌ NeteaseApi Error: $e');
    }
    return [];
  }

  List<LyricLine> _parseLrc(String lrc) {
    final List<LyricLine> lines = [];
    // Support [mm:ss.xx], [mm:ss,xx], and [hh:mm:ss.xx] formats
    // Group 1: optional hours, Group 2: minutes, Group 3: seconds with decimals
    final regExp = RegExp(r'\[(?:(\d+):)?(\d+):(\d+[.,]?\d*)\](.*)');

    for (var line in lrc.split('\n')) {
      final match = regExp.firstMatch(line);
      if (match != null) {
        try {
          final hours = match.group(1) != null ? int.parse(match.group(1)!) : 0;
          final minutes = int.parse(match.group(2)!);
          // Normalize comma to dot for parsing
          final secondsStr = match.group(3)!.replaceAll(',', '.');
          final seconds = double.parse(secondsStr);
          final duration = Duration(
            hours: hours,
            minutes: minutes,
            seconds: seconds.toInt(),
            milliseconds: ((seconds - seconds.toInt()) * 1000).toInt(),
          );
          final text = match.group(4)!.trim();
          if (text.isNotEmpty) {
            lines.add(LyricLine(time: duration, text: text));
          }
        } catch (e) {
          // Skip malformed lines instead of crashing
          debugPrint('⚠️ Skipping malformed LRC line: $line');
        }
      }
    }
    return lines;
  }
}
