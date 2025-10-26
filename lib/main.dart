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
import 'audio_player_service.dart';
import 'playback_controls.dart';
import 'conversion_dialog.dart';
import 'conversion_progress_overlay.dart';
import 'conversion_service.dart';
import 'ffmpeg_progress_parser.dart';

// ... MusicTrack class and other top-level code unchanged ...

class _LibraryPageState extends State<LibraryPage> {
  final List<MusicTrack> _musicTracks = [];
  final List<ConversionJob> _conversionJobs = [];
  final ConversionService _conversionService = ConversionService();
  // ... other state variables unchanged ...

  // ... all methods up to _openConversionDialog are unchanged ...

  void _openConversionDialog(MusicTrack track) async {
    final options = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const ConversionDialog(),
    );

    if (options != null) {
      final format = options['format'] as ConversionFormat;
      final job = ConversionJob(filename: p.basename(track.filePath), progress: 0.0);
      setState(() {
        _conversionJobs.add(job);
      });

      try {
        final inputFile = track.filePath;
        final outputDir = p.join(p.dirname(inputFile), 'Converted Music');
        await Directory(outputDir).create(recursive: true);
        final outputFile = p.join(outputDir, '${p.basenameWithoutExtension(inputFile)}.${format.name}');

        final parser = FFmpegProgressParser();
        final duration = await _audioPlayerService.getDuration(track.filePath);
        if (duration != null) {
          parser.setTotalDuration(duration);
        }

        await _conversionService.convertFile(
          inputFile: inputFile,
          outputFile: outputFile,
          onProgress: (log) {
            final progress = parser.parse(log);
            if (progress >= 0) {
              setState(() {
                job.progress = progress;
              });
            }
          },
        );

        setState(() {
          job.progress = 1.0;
        });
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _conversionJobs.remove(job);
        });
        _loadMusicFromDirectory();

      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Conversion failed: $e')),
        );
        setState(() {
          _conversionJobs.remove(job);
        });
      }
    }
  }

  // ... rest of the methods unchanged ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // ... unchanged ...
      ),
      drawer: Drawer(
        // ... unchanged ...
      ),
      body: Stack( // Use a Stack to overlay the progress widget
        children: [
          Column(
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
                                  onLongPress: () => _editTrack(track),
                                  onTap: () => _audioPlayerService.playPlaylist(_musicTracks, index),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'search') {
                                        _searchOnline(track);
                                      } else if (value == 'convert') {
                                        _openConversionDialog(track);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                      const PopupMenuItem<String>(
                                        value: 'search',
                                        child: ListTile(leading: Icon(Icons.search), title: Text('Search online')),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'convert',
                                        child: ListTile(leading: Icon(Icons.transform), title: Text('Convert')),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ),
              const PlaybackControls(),
            ],
          ),
          ConversionProgressOverlay(jobs: _conversionJobs),
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
