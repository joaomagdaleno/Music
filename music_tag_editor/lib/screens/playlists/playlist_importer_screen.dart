import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:music_tag_editor/services/notification_service.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/models/search_models.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/screens/playlists/views/fluent_playlist_importer_view.dart';
import 'package:music_tag_editor/screens/playlists/views/material_playlist_importer_view.dart';

/// PlaylistImporterScreen controller - platform-adaptive
class PlaylistImporterScreen extends StatefulWidget {
  const PlaylistImporterScreen({super.key});

  @override
  State<PlaylistImporterScreen> createState() => _PlaylistImporterScreenState();
}

class _PlaylistImporterScreenState extends State<PlaylistImporterScreen> {
  final _urlController = TextEditingController();
  final _searchService = SearchService.instance;
  List<SearchResult> _tracks = [];
  bool _isLoading = false;
  String? _error;

  Future<void> _scan() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _tracks = [];
    });
    try {
      final results = await _searchService.importPlaylist(url);
      if (mounted) {
        setState(() {
          _tracks = results;
          _isLoading = false;
          if (_tracks.isEmpty) {
            _error = 'Nenhuma música encontrada.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _importAll() async {
    for (var track in _tracks) {
      await DatabaseService.instance.saveTrack(track.toJson());
    }
    if (mounted) {
      _showNotification('${_tracks.length} músicas importadas!');
      Navigator.pop(context);
    }
  }

  void _showNotification(String message) {
    NotificationService.instance.show(
      context,
      message,
      severity: NotificationSeverity.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    switch (platform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return FluentPlaylistImporterView(
            urlController: _urlController,
            tracks: _tracks,
            isLoading: _isLoading,
            error: _error,
            onScan: _scan,
            onImportAll: _importAll);
      default:
        return MaterialPlaylistImporterView(
            urlController: _urlController,
            tracks: _tracks,
            isLoading: _isLoading,
            error: _error,
            onScan: _scan,
            onImportAll: _importAll);
    }
  }
}
