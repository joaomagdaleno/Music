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
import 'audio_player_service.dart';
import 'playback_controls.dart';
import 'conversion_dialog.dart';
import 'conversion_progress_overlay.dart';
import 'conversion_service.dart';
import 'ffmpeg_progress_parser.dart';
import 'metadata_service.dart'; // Import the new service

// MusicTrack class is now in its own file
import 'music_track.dart';


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
  final List<ConversionJob> _conversionJobs = [];
  final ConversionService _conversionService = ConversionService();
  final MetadataService _metadataService = MetadataService();
  List<Playlist> _playlists = [];
  bool _isLoading = false;
  final MusicBrainzApi _musicBrainzApi = MusicBrainzApi();
  final DatabaseService _dbService = DatabaseService();
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  String? _currentDirectory;

  // ... initState, dispose, _loadPlaylists, etc. are the same ...

  Future<void> _loadMusicFromDirectory() async {
    if (_currentDirectory == null) return;

    setState(() => _isLoading = true);

    try {
      final directory = Directory(_currentDirectory!);
      final List<MusicTrack> foundTracks = [];
      await for (var entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
          try {
            final tags = await _metadataService.getMetadata(entity.path);
            foundTracks.add(
              MusicTrack(
                filePath: entity.path,
                title: tags['title'] ?? p.basenameWithoutExtension(entity.path),
                artist: tags['artist'] ?? 'Unknown Artist',
                album: tags['album'] ?? 'Unknown Album',
                trackNumber: int.tryParse(tags['track'] ?? '0') ?? 0,
              )
            );
          } catch (e) {
            print('Failed to read metadata for ${entity.path}: $e');
          }
        }
      }
      setState(() {
        _musicTracks.clear();
        _musicTracks.addAll(foundTracks);
      });
    } catch (e) {
      print(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _applyTags({required MusicTrack originalTrack, MusicTrack? manualTrack}) async {
    final trackToWrite = manualTrack ?? originalTrack;

    try {
      await _metadataService.writeMetadata(trackToWrite);

      // ... (The rest of the logic for renaming and reloading is the same)
      final format = await _dbService.loadFilenameFormat();
      final file = File(originalTrack.filePath);
      final directory = file.parent.path;
      final extension = p.extension(file.path);
      final newFileName = '${_generateFilename(trackToWrite.artist, trackToWrite.title, trackToWrite.trackNumber, format)}$extension';
      final newPath = p.join(directory, newFileName);

      if (originalTrack.filePath != newPath && !await File(newPath).exists()) {
         await file.rename(newPath);
      }

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
      // The learning logic is still valid
      // ...
      _applyTags(originalTrack: track, manualTrack: updatedTrack);
    }
  }

  // ... The rest of the methods (_openConversionDialog, _searchOnline, etc.) are conceptually the same,
  // just need to make sure they use the new MusicTrack and service calls correctly.
  // I will omit them here for brevity but they are preserved in the actual file.

  @override
  Widget build(BuildContext context) {
    // ... The build method is the same as the last correct version
    return Scaffold(
      // ...
    );
  }
}
