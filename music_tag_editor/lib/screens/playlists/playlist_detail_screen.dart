import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/screens/playlists/views/fluent_playlist_detail_view.dart';
import 'package:music_tag_editor/screens/playlists/views/material_playlist_detail_view.dart';

/// PlaylistDetailScreen controller - platform-adaptive
class PlaylistDetailScreen extends StatefulWidget {
  final int playlistId;
  final String playlistName;

  const PlaylistDetailScreen({
    super.key,
    required this.playlistId,
    required this.playlistName,
  });

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  List<Map<String, dynamic>> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    final tracks = await DatabaseService.instance.getPlaylistTracks(widget.playlistId);
    if (mounted) setState(() { _tracks = tracks; _isLoading = false; });
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
        return FluentPlaylistDetailView(playlistName: widget.playlistName, tracks: _tracks, isLoading: _isLoading, onPlayTrack: _playTrack);
      default:
        return MaterialPlaylistDetailView(playlistName: widget.playlistName, tracks: _tracks, isLoading: _isLoading, onPlayTrack: _playTrack);
    }
  }
}
