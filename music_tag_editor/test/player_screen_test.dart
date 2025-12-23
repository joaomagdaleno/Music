import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_tag_editor/player_screen.dart';
import 'package:music_tag_editor/playback_service.dart';
import 'package:music_tag_editor/local_duo_service.dart';
import 'package:music_tag_editor/lyrics_service.dart';
import 'package:music_tag_editor/database_service.dart';
import 'package:music_tag_editor/theme_service.dart';
import 'package:music_tag_editor/download_service.dart';

class MockPlaybackService extends Mock implements PlaybackService {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockLocalDuoService extends Mock implements LocalDuoService {}

class MockLyricsService extends Mock implements LyricsService {}

class MockDatabaseService extends Mock implements DatabaseService {}

class MockThemeService extends Mock implements ThemeService {}

void main() {
  setUpAll(() {
    registerFallbackValue(Duration.zero);
  });

  group('PlayerScreen Widget Tests', () {
    late MockPlaybackService mockPlayback;
    late MockAudioPlayer mockPlayer;
    late MockLocalDuoService mockDuo;
    late MockLyricsService mockLyrics;
    late MockDatabaseService mockDb;
    late StreamController<PlayerState> playerStateController;
    late StreamController<Duration> positionController;

    setUp(() {
      mockPlayback = MockPlaybackService();
      mockPlayer = MockAudioPlayer();
      mockDuo = MockLocalDuoService();
      mockLyrics = MockLyricsService();
      mockDb = MockDatabaseService();
      playerStateController = StreamController<PlayerState>.broadcast();
      positionController = StreamController<Duration>.broadcast();

      PlaybackService.instance = mockPlayback;
      LocalDuoService.instance = mockDuo;
      LyricsService.instance = mockLyrics;
      DatabaseService.instance = mockDb;
      ThemeService.instance = MockThemeService();

      when(() => mockPlayback.player).thenReturn(mockPlayer);
      when(() => mockPlayback.sleepTimerStream)
          .thenAnswer((_) => Stream.value(null));
      when(() => mockPlayback.lyricsStream).thenAnswer((_) => Stream.value([]));
      when(() => mockPlayback.queue).thenReturn([]);
      when(() => mockPlayback.resume()).thenAnswer((_) async => Future.value());
      when(() => mockPlayback.pause()).thenAnswer((_) async => Future.value());
      when(() => mockPlayback.seek(any()))
          .thenAnswer((_) async => Future.value());

      when(() => mockDuo.role).thenReturn(DuoRole.none);
      when(() => mockPlayer.playerStateStream)
          .thenAnswer((_) => playerStateController.stream);
      when(() => mockPlayer.positionStream)
          .thenAnswer((_) => positionController.stream);
      when(() => mockPlayer.duration).thenReturn(Duration.zero);
    });

    tearDown(() {
      playerStateController.close();
      positionController.close();
    });

    testWidgets('Shows empty state when no track is playing', (tester) async {
      when(() => mockPlayback.currentTrack).thenReturn(null);

      await tester.pumpWidget(const MaterialApp(home: PlayerScreen()));
      await tester.pump(); // Start building

      playerStateController.add(PlayerState(false, ProcessingState.idle));
      await tester.pump();

      expect(find.text('Nenhuma música tocando'), findsOneWidget);
    });

    testWidgets('Shows track info when playing', (tester) async {
      final track = SearchResult(
        id: '1',
        title: 'Test Song',
        artist: 'Test Artist',
        url: 'https://example.com',
        platform: MediaPlatform.youtube,
      );
      when(() => mockPlayback.currentTrack).thenReturn(track);

      await tester.pumpWidget(const MaterialApp(home: PlayerScreen()));

      playerStateController.add(PlayerState(true, ProcessingState.ready));
      await tester.pump();

      expect(find.text('Test Song'), findsWidgets);
      expect(find.text('Test Artist'), findsWidgets);
    });

    testWidgets('Toggles play/pause', (tester) async {
      final track = SearchResult(
        id: '1',
        title: 'Test Song',
        artist: 'Test Artist',
        url: 'https://example.com',
        platform: MediaPlatform.youtube,
      );
      when(() => mockPlayback.currentTrack).thenReturn(track);

      await tester.pumpWidget(const MaterialApp(home: PlayerScreen()));

      // Initially paused
      playerStateController.add(PlayerState(false, ProcessingState.ready));
      await tester.pump();

      final playButton = find.byIcon(Icons.play_arrow);
      expect(playButton, findsOneWidget);

      await tester.tap(playButton);
      verify(() => mockPlayback.resume()).called(1);

      // Simulate playing state update
      playerStateController.add(PlayerState(true, ProcessingState.ready));
      await tester.pump();

      final pauseButton = find.byIcon(Icons.pause);
      expect(pauseButton, findsOneWidget);

      await tester.tap(pauseButton);
      verify(() => mockPlayback.pause()).called(1);
    });

    testWidgets('Shows Duo chat button when in Duo mode', (tester) async {
      final track = SearchResult(
        id: '1',
        title: 'Test Song',
        artist: 'Test Artist',
        url: 'https://example.com',
        platform: MediaPlatform.youtube,
      );
      when(() => mockPlayback.currentTrack).thenReturn(track);
      when(() => mockDuo.role).thenReturn(DuoRole.host);

      await tester.pumpWidget(const MaterialApp(home: PlayerScreen()));

      playerStateController.add(PlayerState(false, ProcessingState.ready));
      await tester.pump();

      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });
  });
}
