import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:music_tag_editor/services/listening_stats_service.dart';
import 'package:music_tag_editor/screens/stats/views/fluent_listening_stats_view.dart';
import 'package:music_tag_editor/screens/stats/views/material_listening_stats_view.dart';

/// ListeningStatsScreen controller - platform-adaptive
class ListeningStatsScreen extends StatefulWidget {
  const ListeningStatsScreen({super.key});

  @override
  State<ListeningStatsScreen> createState() => _ListeningStatsScreenState();
}

class _ListeningStatsScreenState extends State<ListeningStatsScreen> {
  int _totalMinutes = 0;
  List<Map<String, dynamic>> _topArtists = [];
  List<Map<String, dynamic>> _topTracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await ListeningStatsService.instance.getStats();
    if (mounted) {
      setState(() {
        _totalMinutes = stats.estimatedListeningTime.inMinutes;
        _topArtists = stats.topArtists
            .map((e) => {'name': e.key, 'count': e.value})
            .toList();
        _topTracks = stats.topTracks
            .map((e) => {'name': e['title'], 'count': e['play_count']})
            .toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    switch (platform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return FluentListeningStatsView(
            totalMinutes: _totalMinutes,
            topArtists: _topArtists,
            topTracks: _topTracks,
            isLoading: _isLoading);
      default:
        return MaterialListeningStatsView(
            totalMinutes: _totalMinutes,
            topArtists: _topArtists,
            topTracks: _topTracks,
            isLoading: _isLoading);
    }
  }
}
