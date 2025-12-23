import 'dart:io';
import 'dart:convert';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:music_tag_editor/services/download_service.dart';

/// Service for detecting duplicate tracks using audio fingerprints.
class DuplicateDetectorService {
  static final DuplicateDetectorService instance =
      DuplicateDetectorService._internal();
  DuplicateDetectorService._internal();

  final _db = DatabaseService.instance;
  final _deps = DependencyManager.instance;

  // Cache of fingerprints: trackId -> fingerprint hash
  final Map<String, String> _fingerprintCache = {};

  /// Scan library for duplicate tracks.
  Future<List<DuplicateGroup>> findDuplicates({
    void Function(int current, int total)? onProgress,
  }) async {
    final tracks = await _db.getAllTracks();
    final downloadedTracks = tracks
        .where((t) => t.localPath != null && File(t.localPath!).existsSync())
        .toList();

    if (downloadedTracks.length < 2) {
      return [];
    }

    // Generate fingerprints for all tracks
    final fingerprints = <String, List<SearchResult>>{};

    for (int i = 0; i < downloadedTracks.length; i++) {
      onProgress?.call(i + 1, downloadedTracks.length);

      final track = downloadedTracks[i];
      final fp = await _getFingerprint(track.localPath!);

      if (fp != null) {
        // Use first 100 chars of fingerprint as grouping key
        final key = fp.length > 100 ? fp.substring(0, 100) : fp;
        fingerprints.putIfAbsent(key, () => []).add(track);
      }
    }

    // Find groups with more than one track (duplicates)
    final duplicates = <DuplicateGroup>[];

    for (final entry in fingerprints.entries) {
      if (entry.value.length > 1) {
        duplicates.add(DuplicateGroup(
          fingerprint: entry.key,
          tracks: entry.value,
        ));
      }
    }

    return duplicates;
  }

  /// Get fingerprint for an audio file.
  Future<String?> _getFingerprint(String filePath) async {
    // Check cache first
    if (_fingerprintCache.containsKey(filePath)) {
      return _fingerprintCache[filePath];
    }

    try {
      final result = await Process.run(
        _deps.fpcalcPath,
        ['-json', filePath],
        stdoutEncoding: utf8,
      );

      if (result.exitCode != 0) { return null; }

      final json = jsonDecode(result.stdout as String);
      final fingerprint = json['fingerprint'] as String?;

      if (fingerprint != null) {
        _fingerprintCache[filePath] = fingerprint;
      }

      return fingerprint;
    } catch (e) {
      return null;
    }
  }

  /// Quick duplicate check using metadata (title + artist).
  Future<List<DuplicateGroup>> findMetadataDuplicates() async {
    final tracks = await _db.getAllTracks();
    final groups = <String, List<SearchResult>>{};

    for (final track in tracks) {
      // Create a key from normalized title + artist
      final key = '${_normalize(track.title)}|${_normalize(track.artist)}';
      groups.putIfAbsent(key, () => []).add(track);
    }

    return groups.entries
        .where((e) => e.value.length > 1)
        .map((e) => DuplicateGroup(
              fingerprint: e.key,
              tracks: e.value,
              isMetadataMatch: true,
            ))
        .toList();
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Delete duplicate tracks, keeping the best quality version.
  Future<int> deleteDuplicates(
    DuplicateGroup group, {
    bool keepHighestQuality = true,
  }) async {
    if (group.tracks.length < 2) { return 0; }

    // Sort by quality (prefer FLAC > M4A > MP3, then by file size)
    final sorted = List<SearchResult>.from(group.tracks);
    sorted.sort((a, b) {
      final aExt = a.localPath?.split('.').last.toLowerCase() ?? '';
      final bExt = b.localPath?.split('.').last.toLowerCase() ?? '';

      final extOrder = {'flac': 0, 'm4a': 1, 'mp3': 2, 'opus': 3};
      final aOrder = extOrder[aExt] ?? 99;
      final bOrder = extOrder[bExt] ?? 99;

      if (aOrder != bOrder) { return aOrder.compareTo(bOrder); }

      // Compare file sizes (larger = better quality)
      final aSize = a.localPath != null ? File(a.localPath!).lengthSync() : 0;
      final bSize = b.localPath != null ? File(b.localPath!).lengthSync() : 0;
      return bSize.compareTo(aSize);
    });

    // Keep best, delete rest
    final toDelete = sorted.skip(1).toList();
    int deleted = 0;

    for (final track in toDelete) {
      // Delete file
      if (track.localPath != null) {
        final file = File(track.localPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Remove from database
      await _db.deleteTrack(track.id);
      deleted++;
    }

    return deleted;
  }

  void clearCache() {
    _fingerprintCache.clear();
  }
}

/// A group of duplicate tracks.
class DuplicateGroup {
  final String fingerprint;
  final List<SearchResult> tracks;
  final bool isMetadataMatch;

  DuplicateGroup({
    required this.fingerprint,
    required this.tracks,
    this.isMetadataMatch = false,
  });

  /// Get the recommended track to keep (highest quality).
  SearchResult get bestTrack {
    if (tracks.length == 1) { return tracks.first; }

    // Prefer FLAC, then larger files
    return tracks.reduce((best, current) {
      final bestExt = best.localPath?.split('.').last.toLowerCase() ?? '';
      final currExt = current.localPath?.split('.').last.toLowerCase() ?? '';

      if (currExt == 'flac' && bestExt != 'flac') { return current; }
      if (bestExt == 'flac' && currExt != 'flac') { return best; }

      final bestSize =
          best.localPath != null ? File(best.localPath!).lengthSync() : 0;
      final currSize =
          current.localPath != null ? File(current.localPath!).lengthSync() : 0;

      return currSize > bestSize ? current : best;
    });
  }
}


