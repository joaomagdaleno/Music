import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/screens/playlists/views/fluent_playlist_detail_view.dart';
import 'package:music_tag_editor/screens/playlists/views/material_playlist_detail_view.dart';
import 'package:music_tag_editor/screens/player/player_screen.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

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
    debugPrint('[PlaylistDetail] Track data: $trackData');
    
    if (trackData['url'] == null || trackData['url'].toString().isEmpty) {
      debugPrint('[PlaylistDetail] ERROR: Track has no URL!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Esta música não possui URL de reprodução.')),
      );
      return;
    }
    
    final result = SearchResult.fromJson(trackData);
    debugPrint('[PlaylistDetail] Playing: ${result.title} - ${result.url} - ${result.platform}');
    PlaybackService.instance.playSearchResult(result);
    
    if (context.mounted) {
      if (defaultTargetPlatform == TargetPlatform.windows || 
          defaultTargetPlatform == TargetPlatform.linux || 
          defaultTargetPlatform == TargetPlatform.macOS) {
        Navigator.of(context).push(
          fluent.FluentPageRoute(builder: (_) => const PlayerScreen()),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PlayerScreen()),
        );
      }
    }
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
