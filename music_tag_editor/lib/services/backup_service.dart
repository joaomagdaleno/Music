import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:music_tag_editor/services/database_service.dart';
import 'package:meta/meta.dart';

/// Service for backing up and restoring user data.
class BackupService {
  static BackupService _instance = BackupService._internal();
  static BackupService get instance => _instance;

  @visibleForTesting
  static set instance(BackupService mock) => _instance = mock;

  BackupService._internal();

  final _db = DatabaseService.instance;

  /// Create a backup of all user data.
  Future<String> createBackup(String destinationPath) async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupName = 'music_backup_$timestamp';
    final backupDir = Directory(p.join(destinationPath, backupName));
    await backupDir.create(recursive: true);

    // Export database tables
    final tracks = await _db.getTracks();
    final playlists = await _db.getPlaylists();
    final playHistory = await _db.getPlayHistory();
    final settings = await _db.getAllSettings();

    final backupData = {
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'tracks': tracks,
      'playlists': playlists,
      'playHistory': playHistory,
      'settings': settings,
    };

    // Write JSON
    final jsonFile = File(p.join(backupDir.path, 'data.json'));
    await jsonFile.writeAsString(json.encode(backupData));

    // Create ZIP
    final zipPath = '$destinationPath${p.separator}$backupName.zip';
    final archive = Archive();

    await for (var entity in backupDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: backupDir.path);
        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
      }
    }

    final zipData = ZipEncoder().encode(archive);
    if (zipData != null) {
      await File(zipPath).writeAsBytes(zipData);
    }

    // Cleanup temp directory
    await backupDir.delete(recursive: true);

    return zipPath;
  }

  /// Restore data from a backup file.
  Future<int> restoreBackup(String zipPath) async {
    final tempDir = await Directory.systemTemp.createTemp('music_restore_');
    int restoredCount = 0;

    try {
      // Extract ZIP
      final bytes = await File(zipPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (var file in archive) {
        if (file.isFile) {
          final outputPath = p.join(tempDir.path, file.name);
          await Directory(p.dirname(outputPath)).create(recursive: true);
          await File(outputPath).writeAsBytes(file.content as List<int>);
        }
      }

      // Read JSON
      final jsonFile = File(p.join(tempDir.path, 'data.json'));
      if (await jsonFile.exists()) {
        final content = await jsonFile.readAsString();
        final backupData = json.decode(content) as Map<String, dynamic>;

        // Restore tracks
        final tracks = backupData['tracks'] as List? ?? [];
        for (var track in tracks) {
          await _db.saveTrack(track);
          restoredCount++;
        }

        // Restore playlists
        final playlists = backupData['playlists'] as List? ?? [];
        for (var playlist in playlists) {
          await _db.savePlaylist(playlist);
        }

        // Note: Settings restoration could be added if needed
      }
    } finally {
      await tempDir.delete(recursive: true);
    }

    return restoredCount;
  }

  /// Get backup file size estimate (for UI display).
  Future<int> estimateBackupSize() async {
    final tracks = await _db.getTracks();
    final playlists = await _db.getPlaylists();

    // Rough estimate: JSON size
    final data = {
      'tracks': tracks,
      'playlists': playlists,
    };

    return json.encode(data).length;
  }
}
