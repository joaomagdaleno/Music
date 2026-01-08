@Tags(['widget'])
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_hub/features/player/screens/player_screen.dart';
import 'package:music_hub/core/services/local_duo_service.dart';
import 'package:music_hub/features/library/models/search_models.dart';
import 'test_helper.dart';

void main() {
  group('PlayerScreen Widget Tests', () {
    late StreamController<bool> playingController;
    late StreamController<Duration> positionController;

    setUp(() async {
      await setupMusicTest();
      playingController = StreamController<bool>.broadcast();
      positionController = StreamController<Duration>.broadcast();

      // Use controllers for mocking streams
      when(() => mockPlayer.playingStream)
          .thenAnswer((_) => playingController.stream);
      when(() => mockPlayer.positionStream)
          .thenAnswer((_) => positionController.stream);
      when(() => mockPlayer.bufferedPositionStream)
          .thenAnswer((_) => Stream.value(Duration.zero));
      when(() => mockPlayer.durationStream)
          .thenAnswer((_) => Stream.value(Duration.zero));
      when(() => mockPlayer.playerStateStream).thenAnswer((_) =>
          playingController.stream
              .map((p) => PlayerState(p, ProcessingState.ready)));
      when(() => mockPlayer.sequenceStateStream)
          .thenAnswer((_) => const Stream.empty());

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
      when(() => mockPlayer.playerState)
          .thenReturn(PlayerState(false, ProcessingState.ready));

      await tester.pump();

      final playButton = find.byIcon(Icons.play_arrow);
      expect(playButton, findsOneWidget);

      await tester.tap(playButton);
      verify(() => mockPlayback.resume()).called(1);

      // Simulate playing state update
      playingController.add(true);
      // Update state mock to reflect playing
      when(() => mockPlayer.playerState)
          .thenReturn(PlayerState(true, ProcessingState.ready));

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
