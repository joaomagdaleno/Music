import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:taglib_ffi_dart/taglib_ffi_dart.dart' as taglib;
import 'dart:io';
import 'dart:typed_data'; // For Uint8List
import 'musicbrainz_api.dart';
import 'search_results_dialog.dart';
import 'package:path/path.dart' as p;
import 'settings_page.dart';
import 'database_service.dart';
import 'edit_track_dialog.dart';
import 'learning_dialog.dart';
import 'package:media_kit/media_kit.dart';
import 'audio_player_service.dart'; // Import the player service
import 'playback_controls.dart';   // Import the playback controls

// A simple data class to hold music metadata.
class MusicTrack {
  final String filePath;
  final String title;
  final String artist;
  final String album;
  final int trackNumber;
  final Uint8List? albumArt;
  final String? lyrics;

  MusicTrack({
    required this.filePath,
    this.title = 'Unknown Title',
    this.artist = 'Unknown Artist',
    this.album = 'Unknown Album',
    this.trackNumber = 0,
    this.albumArt,
    this.lyrics,
  });
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await taglib.initialize();
  runApp(const MusicTagEditorApp());
}

class MusicTagEditorApp extends StatelessWidget {
  const MusicTagEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Tag Editor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const LibraryPage(title: 'Music Library'),
    );
  }
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, required this.title});

  final String title;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final List<MusicTrack> _musicTracks = [];
  List<Playlist> _playlists = [];
  bool _isLoading = false;
  final MusicBrainzApi _musicBrainzApi = MusicBrainzApi();
  final DatabaseService _dbService = DatabaseService();
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  String? _currentDirectory;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  @override
  void dispose() {
    _audioPlayerService.dispose();
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    final playlists = await _dbService.loadPlaylists();
    setState(() {
      _playlists = playlists;
    });
  }

  Future<void> _saveQueueAsPlaylist() async {
    final sequence = _audioPlayerService.currentPlaylist;
    if (sequence.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Queue is empty!')),
      );
      return;
    }

    final controller = TextEditingController();
    final playlistName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter playlist name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Save')),
        ],
      ),
    );

    if (playlistName != null && playlistName.isNotEmpty) {
      await _dbService.savePlaylist(playlistName, sequence);
      _loadPlaylists(); // Refresh the playlist list
      // ignore: use_build_context_synchronously
      Navigator.pop(context); // Close the drawer
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Playlist "$playlistName" saved!')),
      );
    }
  }

  void _loadPlaylist(Playlist playlist) {
    if (playlist.trackPaths.isEmpty) return;

    final playlistTracks = playlist.trackPaths.map((path) {
      try {
        return _musicTracks.firstWhere((track) => track.filePath == path);
      } catch (e) {
        return null;
      }
    }).where((track) => track != null).cast<MusicTrack>().toList();


    if (playlistTracks.isNotEmpty) {
      _audioPlayerService.playPlaylist(playlistTracks, 0);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find tracks for this playlist.')),
      );
    }
  }

  Future<void> _addMusicFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory != null) {
      _currentDirectory = selectedDirectory;
      _loadMusicFromDirectory();
    }
  }

  Future<void> _loadMusicFromDirectory() async {
    if (_currentDirectory == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final directory = Directory(_currentDirectory!);
      final List<MusicTrack> foundTracks = [];
      await for (var entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
          final metadata = await taglib.readMetadata(entity.path);
          final albumArt = await taglib.readAlbumArt(entity.path);
          foundTracks.add(
            MusicTrack(
              filePath: entity.path,
              title: metadata.title ?? 'Unknown Title',
              artist: metadata.artist ?? 'Unknown Artist',
              album: metadata.album ?? 'Unknown Album',
              trackNumber: metadata.track ?? 0,
              albumArt: albumArt,
              lyrics: metadata.lyrics,
            )
          );
        }
      }
      setState(() {
        _musicTracks.clear();
        _musicTracks.addAll(foundTracks);
      });
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _searchOnline(MusicTrack track) async {
    print('Searching online for: ${track.artist} - ${track.title}');
    try {
      final results = await _musicBrainzApi.searchRecording(
        artist: track.artist,
        title: track.title,
      );

      if (results['recordings'] != null && results['recordings'].isNotEmpty) {
        // ignore: use_build_context_synchronously
        final selectedRecording = await showDialog<dynamic>(
          context: context,
          builder: (BuildContext context) {
            return SearchResultsDialog(recordings: results['recordings']);
          },
        );

        if (selectedRecording != null) {
          _applyTags(originalTrack: track, selectedRecording: selectedRecording);
        }
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No results found online.')),
        );
      }

    } catch (e) {
      print('Error searching online: $e');
    }
  }

  String _generateFilename(String artist, String title, int trackNumber, FilenameFormat format) {
    switch (format) {
      case FilenameFormat.artistTitle:
        return '$artist - $title';
      case FilenameFormat.titleArtist:
        return '$title ($artist)';
      case FilenameFormat.trackArtistTitle:
        final trackStr = trackNumber.toString().padLeft(2, '0');
        return '$trackStr. $artist - $title';
    }
  }

  Future<void> _applyTags({required MusicTrack originalTrack, dynamic selectedRecording, MusicTrack? manualTrack}) async {
    String newTitle, newArtist, newAlbum;
    int newTrackNumber;

    if (selectedRecording != null) {
      newTitle = selectedRecording['title'] as String? ?? originalTrack.title;
      newArtist = selectedRecording['artist-credit']?[0]?['name'] as String? ?? originalTrack.artist;
      newAlbum = selectedRecording['releases']?[0]?['title'] as String? ?? originalTrack.album;
      final trackNumberStr = selectedRecording['releases']?[0]?['media']?[0]?['track-offset']?.toString();
      newTrackNumber = trackNumberStr != null ? int.tryParse(trackNumberStr) ?? originalTrack.trackNumber : originalTrack.trackNumber;

      // Apply learning rules
      final rules = await _dbService.getLearningRules();
      for (var rule in rules) {
        bool artistMatch = rule.choice == LearningChoice.forThisArtist && rule.artist == newArtist;
        bool forAll = rule.choice == LearningChoice.forAll;

        if (artistMatch || forAll) {
          if (rule.field == 'title' && newTitle == rule.originalValue) {
            newTitle = rule.correctedValue;
          }
          if (rule.field == 'artist' && newArtist == rule.originalValue) {
            newArtist = rule.correctedValue;
          }
          if (rule.field == 'album' && newAlbum == rule.originalValue) {
            newAlbum = rule.correctedValue;
          }
        }
      }

    } else if (manualTrack != null) {
      newTitle = manualTrack.title;
      newArtist = manualTrack.artist;
      newAlbum = manualTrack.album;
      newTrackNumber = manualTrack.trackNumber;
    } else {
      return; // Nothing to do
    }


    try {
      await taglib.writeMetadata(
        originalTrack.filePath,
        title: newTitle,
        artist: newArtist,
        album: newAlbum,
        track: newTrackNumber,
      );

      final format = await _dbService.loadFilenameFormat();

      final file = File(originalTrack.filePath);
      final directory = file.parent.path;
      final extension = p.extension(file.path);
      final newFileName = '${_generateFilename(newArtist, newTitle, newTrackNumber, format)}$extension';
      final newPath = p.join(directory, newFileName);

      if (originalTrack.filePath != newPath && !await File(newPath).exists()) {
         await file.rename(newPath);
      }

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated: $newFileName')),
      );

      _loadMusicFromDirectory();

    } catch (e) {
      print('Error applying tags: $e');
    }
  }

  void _editTrack(MusicTrack track) async {
    final updatedTrack = await showDialog<MusicTrack>(
      context: context,
      builder: (context) => EditTrackDialog(track: track),
    );

    if (updatedTrack != null) {
      if (updatedTrack.title != track.title) {
        _handleManualEdit(track, 'title', track.title, updatedTrack.title);
      }
      if (updatedTrack.artist != track.artist) {
        _handleManualEdit(track, 'artist', track.artist, updatedTrack.artist);
      }
      if (updatedTrack.album != track.album) {
        _handleManualEdit(track, 'album', track.album, updatedTrack.album);
      }

      _applyTags(originalTrack: track, manualTrack: updatedTrack);
    }
  }

  void _handleManualEdit(MusicTrack track, String field, String originalValue, String correctedValue) async {
    final choice = await showDialog<LearningChoice>(
      context: context,
      builder: (context) => const LearningDialog(),
    );

    if (choice != null && choice != LearningChoice.justThisOnce) {
      final rule = LearningRule(
        artist: choice == LearningChoice.forThisArtist ? track.artist : null,
        field: field,
        originalValue: originalValue,
        correctedValue: correctedValue,
        choice: choice,
      );
      await _dbService.saveLearningRule(rule);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Learning rule saved!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            AppBar(
              title: const Text('Playlists'),
              automaticallyImplyLeading: false,
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Save queue as playlist'),
              onTap: _saveQueueAsPlaylist,
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _playlists.length,
                itemBuilder: (context, index) {
                  final playlist = _playlists[index];
                  return ListTile(
                    leading: const Icon(Icons.queue_music),
                    title: Text(playlist.name),
                    onTap: () {
                      _loadPlaylist(playlist);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : _musicTracks.isEmpty
                      ? const Text('Add a folder to see your music files.')
                      : ListView.builder(
                          itemCount: _musicTracks.length,
                          itemBuilder: (context, index) {
                            final track = _musicTracks[index];
                            return ListTile(
                              leading: track.albumArt != null
                                  ? Image.memory(track.albumArt!)
                                  : const Icon(Icons.music_note),
                              title: Text(track.title),
                              subtitle: Text('${track.artist} - ${track.album}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.search),
                                tooltip: 'Search Online',
                                onPressed: () => _searchOnline(track),
                              ),
                              onLongPress: () => _editTrack(track),
                              onTap: () => _audioPlayerService.playPlaylist(_musicTracks, index),
                            );
                          },
                        ),
            ),
          ),
          const PlaybackControls(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMusicFolder,
        tooltip: 'Add Music Folder',
        child: const Icon(Icons.create_new_folder_outlined),
      ),
    );
  }
}
