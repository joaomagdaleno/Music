import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:music_tag_editor/services/local_duo_service.dart';
import 'package:music_tag_editor/models/search_models.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/screens/library/views/fluent_remote_library_view.dart';
import 'package:music_tag_editor/screens/library/views/material_remote_library_view.dart';

/// RemoteLibraryScreen controller - platform-adaptive
class RemoteLibraryScreen extends StatefulWidget {
  const RemoteLibraryScreen({super.key});

  @override
  State<RemoteLibraryScreen> createState() => _RemoteLibraryScreenState();
}

class _RemoteLibraryScreenState extends State<RemoteLibraryScreen> {
  List<SearchResult> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    LocalDuoService.instance.onLibraryReceived = (tracks) {
      if (mounted) {
        setState(() {
          _tracks = tracks;
          _isLoading = false;
        });
      }
    };
    _refresh();
  }

  @override
  void dispose() {
    LocalDuoService.instance.onLibraryReceived = null;
    super.dispose();
  }

  void _refresh() {
    setState(() => _isLoading = true);
    LocalDuoService.instance.requestRemoteLibrary();
  }

  void _playTrack(SearchResult track) =>
      PlaybackService.instance.playSearchResult(track);

  void _addToQueue(SearchResult track) {
    PlaybackService.instance.addToQueue(track);
    _showNotification('Adicionado à fila compartilhada!');
  }

  bool get _isFluent => defaultTargetPlatform == TargetPlatform.windows;

  void _showNotification(String message) {
    if (_isFluent) {
      fluent.displayInfoBar(context, builder: (context, close) {
        return fluent.InfoBar(
          title: Text(message),
          severity: fluent.InfoBarSeverity.success,
          onClose: close,
        );
      });
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
        return FluentRemoteLibraryView(
            tracks: _tracks,
            isLoading: _isLoading,
            onRefresh: _refresh,
            onPlayTrack: _playTrack,
            onAddToQueue: _addToQueue);
      default:
        return MaterialRemoteLibraryView(
            tracks: _tracks,
            isLoading: _isLoading,
            onRefresh: _refresh,
            onPlayTrack: _playTrack,
            onAddToQueue: _addToQueue);
    }
  }
}
