import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/security_service.dart';
import 'package:music_tag_editor/screens/playlists/playlist_importer_screen.dart';
import 'package:music_tag_editor/screens/tracks/views/fluent_my_tracks_view.dart';
import 'package:music_tag_editor/screens/tracks/views/material_my_tracks_view.dart';

/// MyTracksScreen controller - platform-adaptive
class MyTracksScreen extends StatefulWidget {
  const MyTracksScreen({super.key});

  @override
  State<MyTracksScreen> createState() => _MyTracksScreenState();
}

class _MyTracksScreenState extends State<MyTracksScreen> {
  List<SearchResult> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    final tracks = await DatabaseService.instance.getTracks();
    if (mounted) {
      setState(() {
        _tracks = tracks.map((t) => SearchResult.fromJson(t)).toList();
        _isLoading = false;
      });
    }
  }

  void _playTrack(SearchResult track) =>
      PlaybackService.instance.playSearchResult(track);

  void _addToVault(SearchResult track) async {
    await DatabaseService.instance.toggleVault(track.id, true);
    _loadTracks();
    _showSuccess('Adicionado ao cofre!');
  }

  void _importPlaylist() {
    if (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux) {
      Navigator.push(context, fluent.FluentPageRoute(builder: (_) => const PlaylistImporterScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaylistImporterScreen()));
    }
  }

  void _showSuccess(String message) {
    if (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux) {
      fluent.displayInfoBar(context, builder: (_, close) => fluent.InfoBar(title: Text(message), severity: fluent.InfoBarSeverity.success, onClose: close));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return FluentMyTracksView(tracks: _tracks, isLoading: _isLoading, onPlayTrack: _playTrack, onAddToVault: _addToVault, onImportPlaylist: _importPlaylist);
      default:
        return MaterialMyTracksView(tracks: _tracks, isLoading: _isLoading, onPlayTrack: _playTrack, onAddToVault: _addToVault, onImportPlaylist: _importPlaylist);
    }
  }
}
