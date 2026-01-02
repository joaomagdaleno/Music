import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:music_tag_editor/screens/home/views/fluent_home_view.dart';
import 'package:music_tag_editor/screens/home/views/material_home_view.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService.instance;
  final PlaybackService _playbackService = PlaybackService.instance;
  List<Map<String, dynamic>> _recentTracks = [];
  bool _isLoading = true;

  bool get _isFluent {
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux ||
        platform == TargetPlatform.macOS;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final tracks = await _dbService.getTracks();
    final sorted = List<Map<String, dynamic>>.from(tracks);
    if (mounted) {
      setState(() {
        _recentTracks = sorted.reversed.take(5).toList();
        _isLoading = false;
      });
    }
  }

  void _playTrack(Map<String, dynamic> trackData) {
    final result = SearchResult(
      id: trackData['id'],
      title: trackData['title'],
      artist: trackData['artist'] ?? '',
      thumbnail: trackData['thumbnail'],
      duration: trackData['duration'],
      url: trackData['url'],
      platform: MediaPlatform.values.firstWhere(
        (e) => e.toString() == trackData['platform'],
        orElse: () => MediaPlatform.unknown,
      ),
      localPath: trackData['local_path'],
    );
    _playbackService.playSearchResult(result);
  }

  @override
  Widget build(BuildContext context) {
    if (_isFluent) {
      return FluentHomeView(
        isLoading: _isLoading,
        recentTracks: _recentTracks,
        onPlayTrack: _playTrack,
      );
    }

    return MaterialHomeView(
      isLoading: _isLoading,
      recentTracks: _recentTracks,
      onPlayTrack: _playTrack,
    );
  }
}
