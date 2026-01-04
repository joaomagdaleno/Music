import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:music_tag_editor/models/music_track.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/metadata_service.dart';
import 'package:music_tag_editor/models/filename_format.dart';
import 'package:music_tag_editor/widgets/edit_track_dialog.dart';
import 'package:music_tag_editor/widgets/learning_dialog.dart';
import 'package:music_tag_editor/services/metadata_aggregator_service.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
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
  final DatabaseService _dbService = DatabaseService.instance;
  final MetadataService _metadataService = MetadataService();
  String? _currentDirectory;

  Future<void> _addMusicFolder() async {
    final String? selectedDirectory =
        await FilePicker.platform.getDirectoryPath();

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
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Clean metadata before searching
      final cleanTitle = SearchService.cleanMetadata(track.title);
      final cleanArtist = SearchService.cleanMetadata(track.artist);

      // 2. Use Aggregator for multi-source results
      final result = await MetadataAggregatorService.instance.aggregateMetadata(
        cleanTitle,
        cleanArtist,
      );

      if (!mounted) return;

      // Automatically apply if results were found with reasonable confidence
      if (result.confidence > 0.3) {
        await _applyTags(
          originalTrack: track,
          aggregatedResult: result,
        );
      } else {
        if (!_isFluent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Could not find high-confidence metadata.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error searching online: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _applyTags({
    required MusicTrack originalTrack,
    AggregatedMetadata? aggregatedResult,
    MusicTrack? manualTrack,
  }) async {
    String newTitle, newArtist, newAlbum, newGenre;
    int newTrackNumber, newYear;

    if (aggregatedResult != null) {
      newTitle = aggregatedResult.title ?? originalTrack.title;
      newArtist = aggregatedResult.artist ?? originalTrack.artist;
      newAlbum = aggregatedResult.album ?? originalTrack.album;
      newGenre = aggregatedResult.genre ?? '';
      newYear = aggregatedResult.year ?? 0;
      newTrackNumber = originalTrack.trackNumber;

      // Apply learning rules
      final rules = await _dbService.getLearningRules();
      for (var rule in rules) {
        final bool artistMatch = rule.choice == LearningChoice.forThisArtist &&
            rule.artist == newArtist;
        final bool forAll = rule.choice == LearningChoice.forAll;

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
      newGenre =
          ''; // Manual edit doesn't support genre yet in MusicTrack model
      newYear = 0;
    } else {
      return; // Nothing to do
    }

    // FIX: File Locking on Windows
    // Check if this track is currently playing. If so, we must stop playback to release the file handle.
    try {
      final currentTrack = PlaybackService.instance.currentTrack;
      if (currentTrack != null &&
          currentTrack.localPath == originalTrack.filePath) {
        debugPrint(
            'Track is currently playing. Stopping playback to release file lock.');
        await PlaybackService.instance.stop();
      }
    } catch (e) {
      debugPrint('Error checking playback status: $e');
    }

    try {
      // Write metadata to the file using dart_tags (pure Dart, cross-platform)
      await _metadataService.writeMetadata(
        originalTrack.filePath,
        title: newTitle,
        artist: newArtist,
        album: newAlbum,
        trackNumber: newTrackNumber,
        genre: newGenre.isNotEmpty ? newGenre : null,
        year: newYear > 0 ? newYear : null,
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

      if (!mounted) return;
      if (!_isFluent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Updated: $newFileName')),
        );
      }

      _loadMusicFromDirectory();

      // Optional: Restore playback if needed (complex because file path changed)
      // For now, simpler to just let user re-play.
    } catch (e) {
      debugPrint('Error applying tags: $e');
      if (!_isFluent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _editTrack(MusicTrack track) async {
    dynamic updatedTrack;

    // Unified adaptive dialog call
    if (_isFluent) {
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

    if (!mounted) return;

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
      if (!mounted) return;
      if (!_isFluent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Learning rule saved!')),
        );
      }
    }
  }

  bool get _isFluent {
    final platform = defaultTargetPlatform;
    return !kIsWeb &&
        (platform == TargetPlatform.windows ||
            platform == TargetPlatform.linux ||
            platform == TargetPlatform.macOS);
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
