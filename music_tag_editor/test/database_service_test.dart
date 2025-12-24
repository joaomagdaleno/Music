@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/views/settings_page.dart';
import 'package:music_tag_editor/widgets/learning_dialog.dart';

void main() {
  late DatabaseService service;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    service = DatabaseService.instance;
    await service.initForTesting(inMemoryDatabasePath);
  });

  group('Settings', () {
    test('save and load filename format', () async {
      await service.saveFilenameFormat(FilenameFormat.artistTitle);
      final format = await service.loadFilenameFormat();
      expect(format, FilenameFormat.artistTitle);
    });

    test('save and load crossfade duration', () async {
      await service.saveCrossfadeDuration(5);
      final duration = await service.loadCrossfadeDuration();
      expect(duration, 5);
    });

    test('save and load age bypass', () async {
      await service.saveAgeBypass(true);
      final enabled = await service.loadAgeBypass();
      expect(enabled, true);
    });
  });

  group('Tracks', () {
    final testTrack = {
      'id': 't1',
      'title': 'Song 1',
      'artist': 'Artist 1',
      'platform': 'youtube',
      'url': 'http://url1',
      'is_vault': 0,
    };

    test('save and retrieve tracks', () async {
      await service.saveTrack(testTrack);
      final tracks = await service.getTracks();
      expect(tracks.any((t) => t['id'] == 't1'), true);
    });

    test('toggle vault', () async {
      await service.saveTrack(testTrack);
      await service.toggleVault('t1', true);

      final tracksNoVault = await service.getTracks(includeVault: false);
      expect(tracksNoVault.any((t) => t['id'] == 't1'), false);

      final allTracks = await service.getTracks(includeVault: true);
      expect(allTracks.any((t) => t['id'] == 't1' && t['is_vault'] == 1), true);
    });

    test('trackPlay increments count and sets lastPlayed', () async {
      await service.saveTrack(testTrack);
      await service.trackPlay('t1');

      final tracks = await service.getTracks();
      final track = tracks.firstWhere((t) => t['id'] == 't1');
      expect(track['play_count'], 1);
      expect(track['last_played'], isNotNull);
    });
  });

  group('Playlists', () {
    test('create playlist and add tracks', () async {
      final playlistId =
          await service.createPlaylist('My List', description: 'Desc');
      await service.saveTrack(
          {'id': 'p_track', 'title': 'T', 'platform': 'yt', 'url': 'u'});
      await service.addTrackToPlaylist(playlistId, 'p_track');

      final playlists = await service.getPlaylists();
      expect(playlists.any((p) => p['name'] == 'My List'), true);

      final tracks = await service.getPlaylistTracks(playlistId);
      expect(tracks.length, 1);
      expect(tracks[0]['id'], 'p_track');
    });
  });

  group('Duo', () {
    test('save guest and add session tracks', () async {
      final guestId = 'g1';
      await service.saveGuest(guestId, 'Guest 1');
      await service.saveTrack(
          {'id': 'd_track', 'title': 'DT', 'platform': 'yt', 'url': 'u'});
      await service.addTrackToDuoSession(guestId, 'd_track');

      final history = await service.getGuestHistory();
      expect(history.any((g) => g['id'] == guestId), true);

      final sessionTracks = await service.getDuoSessionTracks(guestId);
      expect(sessionTracks.length, 1);
      expect(sessionTracks[0]['id'], 'd_track');
    });
  });

  group('Moods', () {
    test('getTracksByMood returns matching genres', () async {
      await service.saveTrack({
        'id': 'm_rock',
        'title': 'Rock Song',
        'genre': 'Rock',
        'platform': 'yt',
        'url': 'u'
      });
      await service.saveTrack({
        'id': 'm_jazz',
        'title': 'Jazz Song',
        'genre': 'Jazz',
        'platform': 'yt',
        'url': 'u'
      });

      final energetic = await service.getTracksByMood('energético');
      expect(energetic.any((t) => t['id'] == 'm_rock'), true);
      expect(energetic.any((t) => t['id'] == 'm_jazz'), false);
    });
  });

  group('Learning Rules', () {
    test('save and get learning rules', () async {
      final rule = LearningRule(
        artist: 'A',
        field: 'title',
        originalValue: 'O',
        correctedValue: 'C',
        choice: LearningChoice.forThisArtist,
      );

      await service.saveLearningRule(rule);
      final rules = await service.getLearningRules();
      expect(rules.length, 1);
      expect(rules[0].correctedValue, 'C');
    });
  });
}
