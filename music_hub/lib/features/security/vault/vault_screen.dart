import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:music_hub/features/library/models/search_models.dart';
import 'package:music_hub/core/services/security_service.dart';
import 'package:music_hub/features/player/services/playback_service.dart';
import 'package:music_hub/core/services/database_service.dart';
import 'package:music_hub/features/security/views/fluent_vault_view.dart';
import 'package:music_hub/features/security/views/material_vault_view.dart';

/// VaultScreen controller - platform-adaptive
class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final _passwordController = TextEditingController();
  bool _isUnlocked = false;
  List<SearchResult> _tracks = [];

  Future<void> _unlock() async {
    final password = _passwordController.text;
    final success = await SecurityService.instance.unlockVault(password);
    if (success) {
      _loadTracks();
    } else {
      _showError('Senha incorreta.');
    }
  }

  Future<void> _loadTracks() async {
    final allTracks = await DatabaseService.instance.getAllTracks();
    if (mounted) {
      setState(() {
        _isUnlocked = true;
        _tracks = allTracks.where((t) => t.isVault).toList();
      });
    }
  }

  void _lock() => setState(() {
        _isUnlocked = false;
        _tracks.clear();
        _passwordController.clear();
      });

  void _playTrack(SearchResult track) =>
      PlaybackService.instance.playSearchResult(track);

  void _removeFromVault(SearchResult track) async {
    await DatabaseService.instance.toggleVault(track.id, false);
    _loadTracks();
  }

  void _showError(String message) {
    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux) {
      fluent.displayInfoBar(context,
          builder: (_, close) => fluent.InfoBar(
              title: Text(message),
              severity: fluent.InfoBarSeverity.error,
              onClose: close));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    switch (platform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return FluentVaultView(
            isUnlocked: _isUnlocked,
            tracks: _tracks,
            passwordController: _passwordController,
            onUnlock: _unlock,
            onLock: _lock,
            onPlayTrack: _playTrack,
            onRemoveFromVault: _removeFromVault);
      default:
        return MaterialVaultView(
            isUnlocked: _isUnlocked,
            tracks: _tracks,
            passwordController: _passwordController,
            onUnlock: _unlock,
            onLock: _lock,
            onPlayTrack: _playTrack,
            onRemoveFromVault: _removeFromVault);
    }
  }
}
