import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:music_tag_editor/services/directory_watcher.dart';

class MusicService {
  final dbService = DatabaseService.instance;
  DirectoryWatcher? _directoryWatcher;

  Future<void> startMonitoring() async {
    final result = await FilePicker.platform.getDirectoryPath();

    if (result != null) {
      final dir = Directory(result);
      _directoryWatcher = DirectoryWatcher(
        directory: dir,
        onFilesChanged: () => _scanDirectory(dir),
      );
      _directoryWatcher?.start();
      _scanDirectory(dir);
    }
  }

  void stopMonitoring() {
    _directoryWatcher?.stop();
  }

  Future<void> _scanDirectory(Directory dir) async {
    final files = dir.listSync(recursive: true);
    for (var file in files) {
      if (file.path.endsWith('.mp3') ||
          file.path.endsWith('.flac') ||
          file.path.endsWith('.aac')) {
        final metadata = await MetadataGod.readMetadata(file.path);
        final db = await dbService.database;
        // Check if the track already exists
        final existing = await db.query(
          'tracks',
          where: 'path = ?',
          whereArgs: [file.path],
        );

        if (existing.isEmpty) {
          await db.insert('tracks', {
            'path': file.path,
            'title': metadata.title ?? 'Unknown Title',
            'artist': metadata.artist ?? 'Unknown Artist',
            'album': metadata.album ?? 'Unknown Album',
            'genre': metadata.genre,
            'albumArt': metadata.picture?.data,
          });
        }
      }
    }
  }
}
