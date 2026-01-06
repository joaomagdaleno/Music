import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:music_hub/core/services/database_service.dart';
import 'package:music_hub/features/library/playlists/views/fluent_playlists_view.dart';
import 'package:music_hub/features/library/playlists/views/material_playlists_view.dart';

/// PlaylistsScreen controller - platform-adaptive
class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  final DatabaseService _dbService = DatabaseService.instance;
  List<Map<String, dynamic>> _playlists = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    final playlists = await _dbService.getPlaylists();
    if (mounted) setState(() => _playlists = playlists);
  }

  void _createPlaylist() async {
    String? name;

    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux) {
      // Fluent dialog
      final controller = TextEditingController();
      name = await fluent.showDialog<String>(
        context: context,
        builder: (_) => fluent.ContentDialog(
          title: const Text('Nova Playlist'),
          content: fluent.TextBox(
              controller: controller,
              placeholder: 'Nome da playlist',
              autofocus: true),
          actions: [
            fluent.Button(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.pop(context)),
            fluent.FilledButton(
                child: const Text('Criar'),
                onPressed: () => Navigator.pop(context, controller.text)),
          ],
        ),
      );
    } else {
      // Material dialog
      final controller = TextEditingController();
      name = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Nova Playlist'),
          content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Nome da playlist'),
              autofocus: true),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Criar')),
          ],
        ),
      );
    }

    if (name != null && name.trim().isNotEmpty) {
      await _dbService.createPlaylist(name.trim());
      _loadPlaylists();
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    switch (platform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return FluentPlaylistsView(
            playlists: _playlists, onCreatePlaylist: _createPlaylist);
      default:
        return MaterialPlaylistsView(
            playlists: _playlists, onCreatePlaylist: _createPlaylist);
    }
  }
}
