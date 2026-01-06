@Tags(['widget'])
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_hub/core/widgets/mini_player.dart';

import 'package:music_hub/features/library/models/search_models.dart';
import 'package:rxdart/rxdart.dart';
import 'test_helper.dart';

void main() {
  group('MiniPlayer Widget Tests', () {
    BehaviorSubject<bool> playingSubject = BehaviorSubject.seeded(false);

    setUp(() async {
      await setupMusicTest();
      // No platform override, uses Windows (Fluent)

      when(() => mockPlayer.playingStream)
          .thenAnswer((_) => playingSubject.stream);
      when(() => mockPlayer.positionStream)
          .thenAnswer((_) => Stream.value(Duration.zero));
      when(() => mockPlayer.bufferedPositionStream)
          .thenAnswer((_) => Stream.value(Duration.zero));
      when(() => mockPlayer.durationStream)
          .thenAnswer((_) => Stream.value(Duration.zero));
      when(() => mockPlayer.volumeStream).thenAnswer((_) => Stream.value(1.0));
      when(() => mockPlayer.loopModeStream)
          .thenAnswer((_) => Stream.value(LoopMode.off));
      when(() => mockPlayer.shuffleModeEnabledStream)
          .thenAnswer((_) => Stream.value(false));
      when(() => mockPlayer.playerStateStream).thenAnswer((_) => playingSubject
          .stream
          .map((p) => PlayerState(p, ProcessingState.ready)));
      when(() => mockPlayer.sequenceStateStream)
          .thenAnswer((_) => const Stream.empty());

      // Explicitly stub currentTrackStream as empty (so startWith(currentTrack) is the only value)
      when(() => mockPlayback.currentTrackStream)
          .thenAnswer((_) => const Stream.empty());
    });

    tearDown(() {
      playingSubject.close();
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('MiniPlayer renders track info', (tester) async {
      final track = SearchResult(
          id: '1',
          title: 'Song',
          artist: 'Artist',
          url: 'url',
          platform: MediaPlatform.youtube,
          duration: 100);
      when(() => mockPlayback.currentTrack).thenReturn(track);

      await tester.pumpWidget(MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: const Scaffold(body: MiniPlayer())));
      await tester.pump();

      expect(find.text('Song'), findsOneWidget);
      expect(find.text('Artist'), findsOneWidget);
    });
  });
}
