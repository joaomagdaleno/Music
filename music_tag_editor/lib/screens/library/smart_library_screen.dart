import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/models/search_models.dart';
import 'package:music_tag_editor/screens/library/views/fluent_smart_library_view.dart';
import 'package:music_tag_editor/screens/library/views/material_smart_library_view.dart';

/// SmartLibraryScreen controller - platform-adaptive
class SmartLibraryScreen extends StatefulWidget {
  const SmartLibraryScreen({super.key});

  @override
  State<SmartLibraryScreen> createState() => _SmartLibraryScreenState();
}

class _SmartLibraryScreenState extends State<SmartLibraryScreen> {
  late Future<List<SearchResult>> _topHitsFuture;
  late Future<List<SearchResult>> _recentDiscoveriesFuture;

  @override
  void initState() {
    super.initState();
    _topHitsFuture = _loadTracks(DatabaseService.instance.getMostPlayed());
    _recentDiscoveriesFuture =
        _loadTracks(DatabaseService.instance.getRecentlyPlayed());
  }

  Future<List<SearchResult>> _loadTracks(
      Future<List<Map<String, dynamic>>> source) async {
    final data = await source;
    return data.map((t) => SearchResult.fromJson(t)).toList();
  }

  void _playTrack(SearchResult track) =>
      PlaybackService.instance.playSearchResult(track);

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    switch (platform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return FluentSmartLibraryView(
            topHitsFuture: _topHitsFuture,
            recentDiscoveriesFuture: _recentDiscoveriesFuture,
            onPlayTrack: _playTrack);
      default:
        return MaterialSmartLibraryView(
            topHitsFuture: _topHitsFuture,
            recentDiscoveriesFuture: _recentDiscoveriesFuture,
            onPlayTrack: _playTrack);
    }
  }
}
