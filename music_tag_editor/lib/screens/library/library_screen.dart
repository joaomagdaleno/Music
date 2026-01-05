import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/metadata_aggregator_service.dart';
import 'package:music_tag_editor/models/search_models.dart';
import 'package:music_tag_editor/screens/library/views/fluent_library_view.dart';
import 'package:music_tag_editor/screens/library/views/material_library_view.dart';
import 'package:music_tag_editor/widgets/edit_track_dialog.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final DatabaseService _dbService = DatabaseService.instance;
  final MetadataAggregatorService _metadataService =
      MetadataAggregatorService.instance;
  List<SearchResult> _musicTracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshLibrary();
  }

  Future<void> _refreshLibrary() async {
    setState(() => _isLoading = true);
    final tracks = await _dbService.getAllTracks();
    if (mounted) {
      setState(() {
        _musicTracks = tracks;
        _isLoading = false;
      });
    }
  }

  void _addMusicFolder() async {
    // Logic for adding folder (simplified for brevity)
    _refreshLibrary();
  }

  void _searchOnline(SearchResult track) async {
    debugPrint('Searching online for: ${track.artist} - ${track.title}');
    setState(() {
      _isLoading = true;
    });

    try {
      final cleanTitle = SearchResult.cleanMetadata(track.title);
      final cleanArtist = SearchResult.cleanMetadata(track.artist);

      await _metadataService.aggregateMetadata(
        cleanTitle,
        cleanArtist,
      );

      if (!mounted) return;
      _refreshLibrary();
    } catch (e) {
      debugPrint('Error searching online: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _editTrack(SearchResult track) async {
    final result = await showDialog<SearchResult>(
      context: context,
      builder: (context) => EditTrackDialog(track: track),
    );

    if (result != null) {
      await _dbService.updateTrackMetadata(
        result.id,
        result.title,
        result.artist,
        result.album ?? '',
      );
      _refreshLibrary();
    }
  }


  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    final isFluent = platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux ||
        platform == TargetPlatform.macOS;

    if (isFluent) {
      return FluentLibraryView(
        title: 'Biblioteca',
        isLoading: _isLoading,
        musicTracks: _musicTracks,
        onAddFolder: _addMusicFolder,
        onSearchOnline: _searchOnline,
        onEditTrack: _editTrack,
      );
    }

    return MaterialLibraryView(
      title: 'Biblioteca',
      isLoading: _isLoading,
      musicTracks: _musicTracks,
      onAddFolder: _addMusicFolder,
      onSearchOnline: _searchOnline,
      onEditTrack: _editTrack,
    );
  }
}
