import 'package:flutter/material.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/metadata_aggregator_service.dart';
import 'package:music_tag_editor/models/search_models.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final DatabaseService _dbService = DatabaseService.instance;
  final MetadataAggregatorService _metadataService = MetadataAggregatorService.instance;
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
      // 1. Clean metadata before searching
      final cleanTitle = SearchResult.cleanMetadata(track.title);
      final cleanArtist = SearchResult.cleanMetadata(track.artist);

      // 2. Use Aggregator for multi-source results
      await _metadataService.aggregateMetadata(
        cleanTitle,
        cleanArtist,
      );

      if (!mounted) return;

      // Handle result (e.g., update track)
      _refreshLibrary();
    } catch (e) {
      debugPrint('Error searching online: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshLibrary,
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _addMusicFolder,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _musicTracks.length,
              itemBuilder: (context, index) {
                final track = _musicTracks[index];
                return ListTile(
                  title: Text(track.title),
                  subtitle: Text(track.artist),
                  trailing: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _searchOnline(track),
                  ),
                );
              },
            ),
    );
}
