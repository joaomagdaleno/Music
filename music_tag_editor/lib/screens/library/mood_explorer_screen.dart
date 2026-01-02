import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/screens/library/views/fluent_mood_explorer_view.dart';
import 'package:music_tag_editor/screens/library/views/material_mood_explorer_view.dart';

/// MoodExplorerScreen controller - platform-adaptive
class MoodExplorerScreen extends StatefulWidget {
  const MoodExplorerScreen({super.key});

  @override
  State<MoodExplorerScreen> createState() => _MoodExplorerScreenState();
}

class _MoodExplorerScreenState extends State<MoodExplorerScreen> {
  Map<String, List<Map<String, dynamic>>> _moodTracks = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMoodData();
  }

  Future<void> _loadMoodData() async {
    final tracks = await DatabaseService.instance.getTracks();
    final Map<String, List<Map<String, dynamic>>> categorized = {};

    for (var track in tracks) {
      final mood = track['mood'] ?? 'Outros';
      if (!categorized.containsKey(mood)) categorized[mood] = [];
      categorized[mood]!.add(track);
    }

    if (mounted) setState(() { _moodTracks = categorized; _isLoading = false; });
  }

  void _playTrack(Map<String, dynamic> trackData) {
    final result = SearchResult.fromJson(trackData);
    PlaybackService.instance.playSearchResult(result);
  }

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    switch (platform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return FluentMoodExplorerView(moodTracks: _moodTracks, isLoading: _isLoading, onPlayTrack: _playTrack);
      default:
        return MaterialMoodExplorerView(moodTracks: _moodTracks, isLoading: _isLoading, onPlayTrack: _playTrack);
    }
  }
}
