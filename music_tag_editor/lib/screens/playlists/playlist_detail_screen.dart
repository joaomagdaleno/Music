import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/models/search_models.dart';
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

  bool get _isFluent => defaultTargetPlatform == TargetPlatform.windows;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    final tracks =
        await DatabaseService.instance.getPlaylistTracks(widget.playlistId);
    if (mounted) {
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    }
  }

  void _playTrack(Map<String, dynamic> trackData) {
    debugPrint('[PlaylistDetail] Track data: $trackData');

    if (trackData['url'] == null || trackData['url'].toString().isEmpty) {
      debugPrint('[PlaylistDetail] ERROR: Track has no URL!');
      _showError('Erro: Esta música não possui URL de reprodução.');
      return;
    }

    final result = SearchResult.fromJson(trackData);
    debugPrint(
        '[PlaylistDetail] Playing: ${result.title} - ${result.url} - ${result.platform}');
    PlaybackService.instance.playSearchResult(result);
  }

  void _showError(String message) {
    if (_isFluent) {
      fluent.displayInfoBar(context, builder: (context, close) => fluent.InfoBar(
            title: Text(message),
            severity: fluent.InfoBarSeverity.error,
            onClose: close,
          ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    switch (platform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return FluentPlaylistDetailView(
            playlistName: widget.playlistName,
            tracks: _tracks,
            isLoading: _isLoading,
            onPlayTrack: _playTrack);
      default:
        return MaterialPlaylistDetailView(
            playlistName: widget.playlistName,
            tracks: _tracks,
            isLoading: _isLoading,
            onPlayTrack: _playTrack);
    }
  }
}
