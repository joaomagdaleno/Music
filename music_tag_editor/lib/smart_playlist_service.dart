import 'dart:math';
import 'database_service.dart';
import 'download_service.dart';

/// Service for generating smart playlists based on natural language criteria.
class SmartPlaylistService {
  static final SmartPlaylistService instance = SmartPlaylistService._internal();
  SmartPlaylistService._internal();

  final _db = DatabaseService.instance;

  // Genre to mood/energy mapping
  static const Map<String, List<String>> _moodGenres = {
    'energetic': [
      'rock',
      'electronic',
      'dance',
      'hip hop',
      'metal',
      'punk',
      'edm'
    ],
    'chill': [
      'jazz',
      'ambient',
      'lo-fi',
      'acoustic',
      'classical',
      'soul',
      'r&b'
    ],
    'happy': ['pop', 'funk', 'disco', 'reggae', 'ska'],
    'sad': ['blues', 'ballad', 'indie', 'folk'],
    'focus': ['classical', 'ambient', 'instrumental', 'lo-fi', 'piano'],
    'workout': ['electronic', 'hip hop', 'rock', 'metal', 'edm', 'dance'],
    'party': ['dance', 'pop', 'electronic', 'hip hop', 'funk', 'disco'],
    'romantic': ['r&b', 'soul', 'jazz', 'ballad', 'acoustic'],
    'relaxing': ['ambient', 'classical', 'jazz', 'acoustic', 'new age'],
  };

  /// Parse a natural language query and generate a playlist.
  Future<SmartPlaylistResult> generatePlaylist(String query) async {
    final parsed = _parseQuery(query.toLowerCase());

    // Get all tracks from library
    final allTracks = await _db.getAllTracks();

    if (allTracks.isEmpty) {
      return SmartPlaylistResult(
        tracks: [],
        query: query,
        error: 'No tracks in library',
      );
    }

    // Filter by mood/genre if specified
    List<SearchResult> filtered = allTracks;
    if (parsed.mood != null) {
      final moodGenres = _moodGenres[parsed.mood] ?? [];
      if (moodGenres.isNotEmpty) {
        filtered = allTracks.where((t) {
          final genre = t.genre?.toLowerCase() ?? '';
          return moodGenres.any((g) => genre.contains(g));
        }).toList();

        // If filtering removed all tracks, use all tracks
        if (filtered.isEmpty) {
          filtered = allTracks;
        }
      }
    }

    // Shuffle for variety
    filtered.shuffle(Random());

    // Select tracks to match target duration
    final selected = <SearchResult>[];
    int totalDuration = 0;
    final targetSeconds = parsed.targetDurationMinutes * 60;

    for (final track in filtered) {
      if (track.duration != null) {
        if (totalDuration + track.duration! <= targetSeconds + 180) {
          // Allow 3 min over
          selected.add(track);
          totalDuration += track.duration!;
        }

        // Stop if we've reached target
        if (totalDuration >= targetSeconds) {
          break;
        }
      }
    }

    // If we couldn't match duration, just pick tracks
    if (selected.isEmpty) {
      final count = (parsed.targetDurationMinutes / 4).round().clamp(5, 20);
      selected.addAll(filtered.take(count));
    }

    return SmartPlaylistResult(
      tracks: selected,
      query: query,
      parsedMood: parsed.mood,
      targetDuration: parsed.targetDurationMinutes,
      actualDuration: totalDuration ~/ 60,
    );
  }

  /// Parse natural language query into criteria.
  _ParsedQuery _parseQuery(String query) {
    int durationMinutes = 30; // Default 30 min
    String? mood;

    // Parse duration
    final hourMatch = RegExp(r'(\d+)\s*h(our|r)?s?').firstMatch(query);
    final minMatch = RegExp(r'(\d+)\s*min(ute)?s?').firstMatch(query);

    if (hourMatch != null) {
      durationMinutes = int.parse(hourMatch.group(1)!) * 60;
    }
    if (minMatch != null) {
      durationMinutes += int.parse(minMatch.group(1)!);
    }

    // Parse mood
    for (final moodKey in _moodGenres.keys) {
      if (query.contains(moodKey)) {
        mood = moodKey;
        break;
      }
    }

    // Check for Portuguese mood words
    if (mood == null) {
      if (query.contains('energético') || query.contains('animado')) {
        mood = 'energetic';
      }
      if (query.contains('calmo') || query.contains('relaxante')) {
        mood = 'chill';
      }
      if (query.contains('feliz') || query.contains('alegre')) {
        mood = 'happy';
      }
      if (query.contains('triste')) {
        mood = 'sad';
      }
      if (query.contains('foco') || query.contains('estudar')) {
        mood = 'focus';
      }
      if (query.contains('treino') || query.contains('academia')) {
        mood = 'workout';
      }
      if (query.contains('festa')) {
        mood = 'party';
      }
      if (query.contains('romântico')) {
        mood = 'romantic';
      }
    }

    return _ParsedQuery(
      targetDurationMinutes: durationMinutes,
      mood: mood,
    );
  }

  /// Create and save a smart playlist to the database.
  Future<int?> createAndSavePlaylist(
    String query, {
    String? customName,
  }) async {
    final result = await generatePlaylist(query);

    if (result.tracks.isEmpty) {
      return null;
    }

    final name = customName ?? 'Smart: $query';
    final playlistId = await _db.createPlaylist(name, description: query);

    for (final track in result.tracks) {
      await _db.addTrackToPlaylist(playlistId, track.id);
    }

    return playlistId;
  }
}

class _ParsedQuery {
  final int targetDurationMinutes;
  final String? mood;

  _ParsedQuery({
    required this.targetDurationMinutes,
    this.mood,
  });
}

/// Result of smart playlist generation.
class SmartPlaylistResult {
  final List<SearchResult> tracks;
  final String query;
  final String? parsedMood;
  final int? targetDuration;
  final int? actualDuration;
  final String? error;

  SmartPlaylistResult({
    required this.tracks,
    required this.query,
    this.parsedMood,
    this.targetDuration,
    this.actualDuration,
    this.error,
  });
}
