import 'package:flutter/material.dart';
import 'database_service.dart';
import 'playback_service.dart';
import 'download_service.dart';

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
  final DatabaseService _dbService = DatabaseService();
  final PlaybackService _playbackService = PlaybackService.instance;
  List<Map<String, dynamic>> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    final tracks = await _dbService.getPlaylistTracks(widget.playlistId);
    setState(() {
      _tracks = tracks;
      _isLoading = false;
    });
  }

  void _playTrack(Map<String, dynamic> trackData) {
    final result = SearchResult(
      id: trackData['id'],
      title: trackData['title'],
      artist: trackData['artist'] ?? '',
      thumbnail: trackData['thumbnail'],
      duration: trackData['duration'],
      url: trackData['url'],
      platform: MediaPlatform.values.firstWhere(
        (e) => e.toString() == trackData['platform'],
        orElse: () => MediaPlatform.unknown,
      ),
    );
    _playbackService.playSearchResult(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.playlistName)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tracks.isEmpty
              ? const Center(child: Text('Esta playlist está vazia.'))
              : ListView.builder(
                  itemCount: _tracks.length,
                  itemBuilder: (context, index) {
                    final track = _tracks[index];
                    return ListTile(
                      leading: track['thumbnail'] != null
                          ? Image.network(track['thumbnail'],
                              width: 40, height: 40)
                          : const Icon(Icons.music_note),
                      title: Text(track['title']),
                      subtitle: Text(track['artist'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _playTrack(track),
                      ),
                    );
                  },
                ),
    );
  }
}
