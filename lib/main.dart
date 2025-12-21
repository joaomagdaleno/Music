import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'musicbrainz_api.dart';
import 'search_results_dialog.dart';
import 'package:path/path.dart' as p;
import 'settings_page.dart';
import 'database_service.dart';
import 'edit_track_dialog.dart';
import 'learning_dialog.dart';
import 'metadata_service.dart';
import 'search_page.dart';
import 'playback_service.dart';
import 'app_shell.dart';

// A simple data class to hold music metadata.
class MusicTrack {
  final String filePath;
  final String title;
  final String artist;
  final String album;
  final int trackNumber;

  MusicTrack({
    required this.filePath,
    this.title = 'Unknown Title',
    this.artist = 'Unknown Artist',
    this.album = 'Unknown Album',
    this.trackNumber = 0,
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PlaybackService.instance.init();
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
      home: const AppShell(),
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
  bool _isLoading = false;
  final MusicBrainzApi _musicBrainzApi = MusicBrainzApi();
  final DatabaseService _dbService = DatabaseService();
  final MetadataService _metadataService = MetadataService();
  String? _currentDirectory;

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
      await for (var entity
          in directory.list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
          // Read metadata for each found mp3 file.
          final metadata = await _metadataService.readMetadata(entity.path);
          foundTracks.add(MusicTrack(
            filePath: entity.path,
            title: metadata['title'] as String,
            artist: metadata['artist'] as String,
            album: metadata['album'] as String,
            trackNumber: metadata['track'] as int,
          ));
        }
      }
      setState(() {
        _musicTracks.clear();
        _musicTracks.addAll(foundTracks);
      });
    } catch (e) {
      // Handle exceptions
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
          _applyTags(
              originalTrack: track, selectedRecording: selectedRecording);
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

  String _generateFilename(
      String artist, String title, int trackNumber, FilenameFormat format) {
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

  Future<void> _applyTags(
      {required MusicTrack originalTrack,
      dynamic selectedRecording,
      MusicTrack? manualTrack}) async {
    String newTitle, newArtist, newAlbum;
    int newTrackNumber;

    if (selectedRecording != null) {
      newTitle = selectedRecording['title'] as String? ?? originalTrack.title;
      newArtist = selectedRecording['artist-credit']?[0]?['name'] as String? ??
          originalTrack.artist;
      newAlbum = selectedRecording['releases']?[0]?['title'] as String? ??
          originalTrack.album;
      final trackNumberStr = selectedRecording['releases']?[0]?['media']?[0]
              ?['track-offset']
          ?.toString();
      newTrackNumber = trackNumberStr != null
          ? int.tryParse(trackNumberStr) ?? originalTrack.trackNumber
          : originalTrack.trackNumber;

      // Apply learning rules
      final rules = await _dbService.getLearningRules();
      for (var rule in rules) {
        bool artistMatch = rule.choice == LearningChoice.forThisArtist &&
            rule.artist == newArtist;
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
      // Write metadata to the file using dart_tags (pure Dart, cross-platform)
      await _metadataService.writeMetadata(
        originalTrack.filePath,
        title: newTitle,
        artist: newArtist,
        album: newAlbum,
        trackNumber: newTrackNumber,
      );

      // Load the preferred filename format.
      final format = await _dbService.loadFilenameFormat();

      // Rename the file.
      final file = File(originalTrack.filePath);
      final directory = file.parent.path;
      final extension = p.extension(file.path);
      final newFileName =
          '${_generateFilename(newArtist, newTitle, newTrackNumber, format)}$extension';
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

  void _handleManualEdit(MusicTrack track, String field, String originalValue,
      String correctedValue) async {
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
            icon: const Icon(Icons.download),
            tooltip: 'Download Music',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _musicTracks.isEmpty
                ? const Text('Add a folder to see your music files.')
                : ListView.builder(
                    itemCount: _musicTracks.length,
                    itemBuilder: (context, index) {
                      final track = _musicTracks[index];
                      return ListTile(
                        leading: const Icon(Icons.music_note),
                        title: Text(track.title),
                        subtitle: Text('${track.artist} - ${track.album}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.search),
                          tooltip: 'Search Online',
                          onPressed: () => _searchOnline(track),
                        ),
                        onLongPress: () => _editTrack(track),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMusicFolder,
        tooltip: 'Add Music Folder',
        child: const Icon(Icons.create_new_folder_outlined),
      ),
    );
  }
}
