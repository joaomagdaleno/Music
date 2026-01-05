@Tags(['widget'])
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:media_kit/media_kit.dart';
import 'package:music_tag_editor/screens/player/player_screen.dart';
import 'package:music_tag_editor/services/local_duo_service.dart';
import 'package:music_tag_editor/models/search_models.dart';
import 'test_helper.dart';

// Custom Fake Stream to allow controlling stream events
class CustomizablePlayerStream extends Fake implements PlayerStream {
  final StreamController<bool> playingController;
  final StreamController<Duration> positionController;

  CustomizablePlayerStream(this.playingController, this.positionController);

  @override
  Stream<bool> get playing => playingController.stream;
  @override
  Stream<Duration> get position => positionController.stream;

  @override
  Stream<Duration> get buffer => Stream.value(Duration.zero);
  @override
  Stream<Duration> get duration => Stream.value(Duration.zero);
  @override
  Stream<bool> get completed => Stream.value(false);
  @override
  Stream<double> get volume => Stream.value(100.0);
  @override
  Stream<PlaylistMode> get playlistMode => Stream.value(PlaylistMode.none);
  @override
  Stream<bool> get shuffle => Stream.value(false);
  @override
  Stream<double> get pitch => Stream.value(1.0);
  @override
  Stream<double> get rate => Stream.value(1.0);
  @override
  Stream<PlayerLog> get log => const Stream.empty();
}

void main() {
  group('PlayerScreen Widget Tests', () {
    late StreamController<bool> playingController;
    late StreamController<Duration> positionController;

    setUp(() async {
      await setupMusicTest();
      playingController = StreamController<bool>.broadcast();
      positionController = StreamController<Duration>.broadcast();

      // Use customizable stream for mocking
      when(() => mockPlayer.stream).thenReturn(
          CustomizablePlayerStream(playingController, positionController));

      // Default state stubbing
      when(() => mockPlayer.state).thenReturn(const PlayerState());

      when(() => mockPlayback.sleepTimerStream)
          .thenAnswer((_) => Stream.value(null));
      when(() => mockPlayback.lyricsStream).thenAnswer((_) => Stream.value([]));
      when(() => mockPlayback.resume()).thenAnswer((_) async => Future.value());
      when(() => mockPlayback.pause()).thenAnswer((_) async => Future.value());
      when(() => mockPlayback.seek(any()))
          .thenAnswer((_) async => Future.value());

      when(() => mockDuo.role).thenReturn(DuoRole.none);
    });

    tearDown(() {
      playingController.close();
      positionController.close();
    });

    testWidgets('Shows empty state when no track is playing', (tester) async {
      when(() => mockPlayback.currentTrack).thenReturn(null);
      // We need to emit initial state

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const PlayerScreen(),
      ));

      await tester.pump(); // Start building

      playingController.add(false);
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

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const PlayerScreen(),
      ));

      playingController.add(true);
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

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const PlayerScreen(),
      ));

      // Initially paused
      playingController.add(false);
      when(() => mockPlayer.state).thenReturn(const PlayerState(
          playing: false)); // state getter is used for button icon?
      // Wait, StreamBuilder usually drives UI. But if UI checks player.state.playing directly, we need to stub state getter too.
      // But we can't update state valid return dynamically easily unless we use a variable.

      // Let's assume StreamBuilder logic handles it. But PlayerScreen might check `playback.player.state.playing`.
      // The `PlayerScreen` likely listens to `stream.playing`.

      await tester.pump();

      final playButton = find.byIcon(Icons.play_arrow);
      expect(playButton, findsOneWidget);

      await tester.tap(playButton);
      verify(() => mockPlayback.resume()).called(1);

      // Simulate playing state update
      playingController.add(true);
      // Update state mock to reflect playing
      when(() => mockPlayer.state).thenReturn(const PlayerState(playing: true));

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

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const PlayerScreen(),
      ));

      playingController.add(false);
      await tester.pump();

      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
    });
  });
}
