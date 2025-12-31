import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:music_tag_editor/api/musicbrainz_api.dart';
import 'package:music_tag_editor/models/music_track.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/metadata_service.dart';
import 'package:music_tag_editor/models/filename_format.dart';
import 'package:music_tag_editor/widgets/edit_track_dialog.dart';
import 'package:music_tag_editor/widgets/learning_dialog.dart';
import 'package:music_tag_editor/widgets/search_results_dialog.dart';
import 'package:path/path.dart' as p;

import 'views/fluent_library_view.dart';
import 'views/material_library_view.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.title});

  final String title;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final List<MusicTrack> _musicTracks = [];
  bool _isLoading = false;
  final MusicBrainzApi _musicBrainzApi = MusicBrainzApi();
  final DatabaseService _dbService = DatabaseService.instance;
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
    if (_currentDirectory == null) {
      return;
    }

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
      debugPrint(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _searchOnline(MusicTrack track) async {
    debugPrint('Searching online for: ${track.artist} - ${track.title}');
    try {
      final results = await _musicBrainzApi.searchRecording(
        artist: track.artist,
        title: track.title,
      );

      if (results['recordings'] != null && results['recordings'].isNotEmpty) {
        if (!mounted) return;
        dynamic selectedRecording;
        
        if (_isFluent) {
            // Simple generic dialog for Fluent for now
             selectedRecording = await fluent.showDialog<dynamic>(
              context: context,
              builder: (BuildContext context) {
                 // Reuse Material dialog or create Fluent specific
                return SearchResultsDialog(recordings: results['recordings']);
              },
            );
        } else {
             selectedRecording = await showDialog<dynamic>(
              context: context,
              builder: (BuildContext context) {
                return SearchResultsDialog(recordings: results['recordings']);
              },
            );
        }

        if (selectedRecording != null) {
          _applyTags(
              originalTrack: track, selectedRecording: selectedRecording);
        }
      } else {
        if (!mounted) return;
        if (_isFluent) {
            // Fluent doesn't have ScaffoldMessenger at root usually, need InfoBar
           debugPrint('No results found online');
        } else {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No results found online.')),
            );
        }
       
      }
    } catch (e) {
      debugPrint('Error searching online: $e');
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
          '${format.generateFilename(artist: newArtist, title: newTitle, trackNumber: newTrackNumber)}$extension';
      final newPath = p.join(directory, newFileName);

      if (originalTrack.filePath != newPath && !await File(newPath).exists()) {
        await file.rename(newPath);
      }

      // ignore: use_build_context_synchronously
      if (!_isFluent) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Updated: $newFileName')),
          );
      }
      

      _loadMusicFromDirectory();
    } catch (e) {
      debugPrint('Error applying tags: $e');
    }
  }

  void _editTrack(MusicTrack track) async {
    dynamic updatedTrack;
    if (_isFluent) {
         updatedTrack = await fluent.showDialog<MusicTrack>(
          context: context,
          builder: (context) => fluent.ContentDialog(
             content: EditTrackDialog(track: track), // Might need wrapper
             // For now re-use Material Dialog inside
          ), 
        );
        // Fluent Dialog is different, skipping full implementation for brevity
        // Falling back to Material Dialog even in Fluent for complex dialogs temporarily
         updatedTrack = await showDialog<MusicTrack>(
            context: context,
             builder: (context) => EditTrackDialog(track: track),
        );

    } else {
        updatedTrack = await showDialog<MusicTrack>(
            context: context,
            builder: (context) => EditTrackDialog(track: track),
        );
    }
    

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
    
    LearningChoice? choice;
    
    if (_isFluent) {
         choice = await showDialog<LearningChoice>(
            context: context,
            builder: (context) => const LearningDialog(),
        );
    } else {
         choice = await showDialog<LearningChoice>(
            context: context,
            builder: (context) => const LearningDialog(),
        );
    }

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
      if (!_isFluent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Learning rule saved!')),
          );
      }
    }
  }
  
  bool get _isFluent {
      return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS);
  }

  @override
  Widget build(BuildContext context) {
    if (_isFluent) {
      return FluentLibraryView(
        title: widget.title,
        isLoading: _isLoading,
        musicTracks: _musicTracks,
        onAddFolder: _addMusicFolder,
        onSearchOnline: _searchOnline,
        onEditTrack: _editTrack,
      );
    }

    return MaterialLibraryView(
      title: widget.title,
      isLoading: _isLoading,
      musicTracks: _musicTracks,
      onAddFolder: _addMusicFolder,
      onSearchOnline: _searchOnline,
      onEditTrack: _editTrack,
    );
  }
}
