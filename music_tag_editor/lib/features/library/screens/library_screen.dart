import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:music_hub/core/services/database_service.dart';
import 'package:music_hub/features/library/services/metadata_aggregator_service.dart';
import 'package:music_hub/models/search_models.dart';
import 'package:music_hub/features/library/screens/views/fluent_library_view.dart';
import 'package:music_hub/features/library/screens/views/material_library_view.dart';
import 'package:music_hub/features/library/screens/tag_editor_screen.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

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
  bool _isGridView = false;
  String _sortBy = 'title'; // 'title', 'artist', 'year', 'confidence'

  @override
  void initState() {
    super.initState();
    _refreshLibrary();
  }

  Future<void> _refreshLibrary() async {
    setState(() => _isLoading = true);
    final tracks = await _dbService.getAllTracks();
    _sortTracks(tracks);
    if (mounted) {
      setState(() {
        _musicTracks = tracks;
        _isLoading = false;
      });
    }
  }

  void _sortTracks(List<SearchResult> tracks) {
    switch (_sortBy) {
      case 'artist':
        tracks.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
        break;
      case 'year':
        // Assuming year might be in album or not present yet, using title as fallback
        tracks.sort((a, b) => (a.album ?? '').compareTo(b.album ?? ''));
        break;
      case 'confidence':
        // Placeholder for confidence logic if implemented in models
        break;
      default:
        tracks.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
  }

  void _toggleView() {
    setState(() => _isGridView = !_isGridView);
  }

  void _changeSort(String sort) {
    setState(() {
      _sortBy = sort;
      _sortTracks(_musicTracks);
    });
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
    final platform = defaultTargetPlatform;
    final isFluent = !kIsWeb && platform == TargetPlatform.windows;

    final dynamic result = await Navigator.push(
      context,
      isFluent 
        ? fluent.FluentPageRoute(builder: (context) => TagEditorScreen(track: track))
        : MaterialPageRoute(builder: (context) => TagEditorScreen(track: track)),
    );

    if (result == true) {
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
        isGridView: _isGridView,
        sortBy: _sortBy,
        onAddFolder: _addMusicFolder,
        onSearchOnline: _searchOnline,
        onEditTrack: _editTrack,
        onToggleView: _toggleView,
        onSortChanged: _changeSort,
      );
    }

    return MaterialLibraryView(
      title: 'Biblioteca',
      isLoading: _isLoading,
      musicTracks: _musicTracks,
      isGridView: _isGridView,
      sortBy: _sortBy,
      onAddFolder: _addMusicFolder,
      onSearchOnline: _searchOnline,
      onEditTrack: _editTrack,
      onToggleView: _toggleView,
      onSortChanged: _changeSort,
    );
  }
}
