import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_player/mini_player.dart';
import 'package:music_player/playback_service.dart';
import 'package:music_player/download_service.dart';

class MockPlaybackService extends Mock implements PlaybackService {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  group('MiniPlayer Widget Tests', () {
    late MockPlaybackService mockPlayback;
    late MockAudioPlayer mockPlayer;

    setUp(() {
      mockPlayback = MockPlaybackService();
      mockPlayer = MockAudioPlayer();
      PlaybackService.instance = mockPlayback;

      when(() => mockPlayback.player).thenReturn(mockPlayer);
      when(() => mockPlayer.playerStateStream).thenAnswer((_) => Stream.value(
            PlayerState(false, ProcessingState.ready),
          ));
    });

    testWidgets('Shows nothing when no track is playing', (tester) async {
      when(() => mockPlayback.currentTrack).thenReturn(null);

      await tester
          .pumpWidget(const MaterialApp(home: Scaffold(body: MiniPlayer())));

      expect(find.byType(Container), findsNothing);
    });

    testWidgets('Shows track info and controls when track is present',
        (tester) async {
      final track = SearchResult(
        id: '1',
        title: 'Test Song',
        artist: 'Test Artist',
        url: 'https://example.com',
        platform: MediaPlatform.youtube,
      );
      when(() => mockPlayback.currentTrack).thenReturn(track);
      when(() => mockPlayer.playerStateStream).thenAnswer((_) => Stream.value(
            PlayerState(true, ProcessingState.ready),
          ));

      await tester
          .pumpWidget(const MaterialApp(home: Scaffold(body: MiniPlayer())));
      await tester.pump(); // Handle StreamBuilder

      expect(find.text('Test Song'), findsOneWidget);
      expect(find.text('Test Artist'), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('Pause button calls playback.pause', (tester) async {
      final track = SearchResult(
        id: '1',
        title: 'Test Song',
        artist: 'Test Artist',
        url: 'https://example.com',
        platform: MediaPlatform.youtube,
      );
      when(() => mockPlayback.currentTrack).thenReturn(track);
      when(() => mockPlayer.playerStateStream).thenAnswer((_) => Stream.value(
            PlayerState(true, ProcessingState.ready),
          ));
      when(() => mockPlayback.pause()).thenAnswer((_) async {});

      await tester
          .pumpWidget(const MaterialApp(home: Scaffold(body: MiniPlayer())));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.pause));
      verify(() => mockPlayback.pause()).called(1);
    });
  });
}
