import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:music_hub/core/services/database_service.dart';
import 'package:music_hub/features/library/services/metadata_service.dart';
import 'package:music_hub/features/library/screens/views/fluent_local_sources_view.dart';
import 'package:music_hub/features/library/screens/views/material_local_sources_view.dart';

/// LocalSourcesScreen controller - platform-adaptive
class LocalSourcesScreen extends StatefulWidget {
  final MetadataService? metadataService;

  const LocalSourcesScreen({super.key, this.metadataService});

  @override
  State<LocalSourcesScreen> createState() => _LocalSourcesScreenState();
}

class _LocalSourcesScreenState extends State<LocalSourcesScreen> {
  final DatabaseService _dbService = DatabaseService.instance;
  late final MetadataService _metadataService;
  List<Map<String, dynamic>> _folders = [];
  bool _isLoading = true;
  bool _isScanning = false;
  String _scanStatus = '';

  @override
  void initState() {
    super.initState();
    _metadataService = widget.metadataService ?? MetadataService();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final folders = await _dbService.getMusicFolders();
    if (mounted) {
      setState(() {
        _folders = folders;
        _isLoading = false;
      });
    }
  }

  Future<void> _addFolder() async {
    final String? selectedDirectory =
        await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      await _dbService.addMusicFolder(selectedDirectory);
      _loadFolders();
    }
  }

  Future<void> _removeFolder(String path) async {
    await _dbService.removeMusicFolder(path);
    _loadFolders();
  }

  Future<void> _scanAllFolders() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _scanStatus = 'Iniciando...';
    });

    int totalTracksFound = 0;

    for (final folder in _folders) {
      final path = folder['path'] as String;
      setState(() => _scanStatus = 'Escaneando: $path');

      try {
        final directory = Directory(path);
        if (!await directory.exists()) continue;

        await for (var entity
            in directory.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            final path = entity.path.toLowerCase();
            if (path.endsWith('.mp3') ||
                path.endsWith('.wav') ||
                path.endsWith('.flac') ||
                path.endsWith('.m4a')) {
              try {
                // Read metadata if audio
                String title = entity.uri.pathSegments.last;
                String artist = 'Desconhecido';
                String? album;

                try {
                  final metadata =
                      await _metadataService.readMetadata(entity.path);
                  title = metadata['title'] ??
                      title.replaceAll(RegExp(r'\.(mp3|wav|flac|m4a)$'), '');
                  artist = metadata['artist'] ?? artist;
                  album = metadata['album'];
                } catch (e) {
                  // ignore metadata read errors
                }

                await _dbService.saveTrack({
                  'id': entity.path.hashCode.toString(),
                  'title': title,
                  'artist': artist,
                  'album': album,
                  'platform': 'MediaPlatform.local',
                  'url': entity.path,
                  'local_path': entity.path,
                  'is_downloaded': 1,
                  'media_type': 'audio',
                });
                totalTracksFound++;
                if (totalTracksFound % 10 == 0) {
                  setState(() => _scanStatus =
                      '$totalTracksFound arquivos encontrados...');
                }
              } catch (e) {
                debugPrint('Error processing file ${entity.path}: $e');
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error scanning folder $path: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isScanning = false;
        _isScanning = false;
        _scanStatus = 'Concluído! $totalTracksFound arquivos importados.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    switch (platform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return FluentLocalSourcesView(
          folders: _folders,
          isLoading: _isLoading,
          isScanning: _isScanning,
          scanStatus: _scanStatus,
          onAddFolder: _addFolder,
          onRemoveFolder: _removeFolder,
          onScanAll: _scanAllFolders,
        );
      default:
        return MaterialLocalSourcesView(
          folders: _folders,
          isLoading: _isLoading,
          isScanning: _isScanning,
          scanStatus: _scanStatus,
          onAddFolder: _addFolder,
          onRemoveFolder: _removeFolder,
          onScanAll: _scanAllFolders,
        );
    }
  }
}
