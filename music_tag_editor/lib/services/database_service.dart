import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:music_tag_editor/src/rust/api/database.dart' as rust;
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/widgets/learning_dialog.dart';

class LearningRule {
  final String? artist;
  final String field;
  final String originalValue;
  final String correctedValue;
  final LearningChoice choice;

  LearningRule({
    this.artist,
    required this.field,
    required this.originalValue,
    required this.correctedValue,
    required this.choice,
  });
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;

  DatabaseService._internal();

  String? _dbPath;

  Future<String> get _path async {
    if (_dbPath != null) return _dbPath!;
    final docsDir = await getApplicationDocumentsDirectory();
    _dbPath = p.join(docsDir.path, 'music_tag_editor_v2.db');
    await rust.initDb(dbPath: _dbPath!);
    return _dbPath!;
  }

  Future<void> saveLearningRule(LearningRule rule) async {
    final path = await _path;
    await rust.saveLearningRule(
      dbPath: path,
      rule: rust.LearningRule(
        artist: rule.artist,
        field: rule.field,
        originalValue: rule.originalValue,
        correctedValue: rule.correctedValue,
      ),
    );
  }

  Future<List<LearningRule>> getLearningRules() async {
    final path = await _path;
    final rules = await rust.getLearningRules(dbPath: path);
    return rules.map((r) => LearningRule(
      artist: r.artist,
      field: r.field,
      originalValue: r.originalValue,
      correctedValue: r.correctedValue,
      choice: LearningChoice.applyToAll, // Default since choice isn't in Rust yet
    )).toList();
  }

  Future<void> saveTrack(Map<String, dynamic> track) async {
    final path = await _path;
    await rust.saveTrack(
      dbPath: path,
      track: rust.DbTrack(
        id: track['id'],
        title: track['title'],
        artist: track['artist'] ?? '',
        album: track['album'],
        localPath: track['local_path'] ?? '',
      ),
    );
  }

  Future<List<SearchResult>> getAllTracks() async {
    final path = await _path;
    final tracks = await rust.getAllTracks(dbPath: path);
    return tracks.map((t) => SearchResult(
      id: t.id,
      title: t.title,
      artist: t.artist,
      album: t.album,
      localPath: t.localPath,
      platform: MediaPlatform.unknown,
      url: '',
    )).toList();
  }
  
  // Settings methods would use a settings table in Rust similarly
}
