import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/views/playlist_detail_screen.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/download_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

class MockPlaybackService extends Mock implements PlaybackService {}

void main() {
  late MockDatabaseService mockDb;
  late MockPlaybackService mockPlayback;

  setUpAll(() {
    registerFallbackValue(SearchResult(
      id: 'fallback',
      title: 'Fallback',
      artist: 'Fallback',
      url: 'http://fallback',
      platform: MediaPlatform.youtube,
    ));
  });

  setUp(() {
    mockDb = MockDatabaseService();
    mockPlayback = MockPlaybackService();

    DatabaseService.instance = mockDb;
    PlaybackService.instance = mockPlayback;

    when(() => mockPlayback.playSearchResult(any())).thenAnswer((_) async {});
  });

  Widget createTestWidget(
      {int playlistId = 1, String playlistName = 'Test Playlist'}) {
    return MaterialApp(
      home: PlaylistDetailScreen(
        playlistId: playlistId,
        playlistName: playlistName,
      ),
    );
  }

  group('PlaylistDetailScreen', () {
    testWidgets('shows loading indicator initially', (tester) async {
      final completer = Completer<List<Map<String, dynamic>>>();
      when(() => mockDb.getPlaylistTracks(any()))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('displays playlist name in app bar', (tester) async {
      when(() => mockDb.getPlaylistTracks(any())).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget(playlistName: 'My Playlist'));
      await tester.pumpAndSettle();

      expect(find.text('My Playlist'), findsOneWidget);
    });

    testWidgets('shows empty state when no tracks', (tester) async {
      when(() => mockDb.getPlaylistTracks(any())).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Esta playlist está vazia.'), findsOneWidget);
    });

    testWidgets('shows track list when tracks exist', (tester) async {
      when(() => mockDb.getPlaylistTracks(any())).thenAnswer((_) async => [
            {
              'id': '1',
              'title': 'Song 1',
              'artist': 'Artist 1',
              'url': 'http://1',
              'platform': 'MediaPlatform.youtube'
            },
            {
              'id': '2',
              'title': 'Song 2',
              'artist': 'Artist 2',
              'url': 'http://2',
              'platform': 'MediaPlatform.youtube'
            },
          ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Song 1'), findsOneWidget);
      expect(find.text('Song 2'), findsOneWidget);
    });

    testWidgets('has play button for each track', (tester) async {
      when(() => mockDb.getPlaylistTracks(any())).thenAnswer((_) async => [
            {
              'id': '1',
              'title': 'Song 1',
              'artist': 'Artist 1',
              'url': 'http://1',
              'platform': 'MediaPlatform.youtube'
            },
          ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('calls playSearchResult on play button tap', (tester) async {
      when(() => mockDb.getPlaylistTracks(any())).thenAnswer((_) async => [
            {
              'id': '1',
              'title': 'Song 1',
              'artist': 'Artist 1',
              'url': 'http://1',
              'platform': 'MediaPlatform.youtube'
            },
          ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      verify(() => mockPlayback.playSearchResult(any())).called(1);
    });
  });
}
