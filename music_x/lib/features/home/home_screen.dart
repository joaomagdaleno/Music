import 'package:flutter/material.dart';
import 'package:music_hub/features/home/views/fluent_home_view.dart';
import 'package:music_hub/features/home/views/material_home_view.dart';
import 'package:music_hub/core/services/database_service.dart';
import 'package:music_hub/features/library/models/search_models.dart';
import 'package:music_hub/features/player/services/playback_service.dart';

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

  bool _isFluent(BuildContext context) {
    final platform = Theme.of(context).platform;
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
    final result = SearchResult.fromJson(trackData);
    _playbackService.playSearchResult(result);
  }

  @override
  Widget build(BuildContext context) {
    if (_isFluent(context)) {
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
