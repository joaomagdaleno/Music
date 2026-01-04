@Tags(['widget'])
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:media_kit/media_kit.dart';
import 'package:music_tag_editor/widgets/mini_player.dart';

import 'package:music_tag_editor/services/download_service.dart';
import 'package:rxdart/rxdart.dart';
import 'test_helper.dart';

// MockPlayerStream defined locally or in test_helper (not in test_helper yet, but MockPlayer is)
class MockPlayerStream extends Mock implements PlayerStream {}

void main() {
  group('MiniPlayer Widget Tests', () {
    late MockPlayerStream mockStream;
    late BehaviorSubject<bool> playingSubject;

    setUp(() async {
      await setupMusicTest();
      // No platform override, uses Windows (Fluent)

      mockStream = MockPlayerStream();
      playingSubject = BehaviorSubject.seeded(false);

      when(() => mockPlayer.stream).thenReturn(mockStream);
      when(() => mockPlayer.state).thenReturn(const PlayerState());

      when(() => mockStream.playing).thenAnswer((_) => playingSubject.stream);
      when(() => mockStream.position)
          .thenAnswer((_) => Stream.value(Duration.zero));
      when(() => mockStream.duration)
          .thenAnswer((_) => Stream.value(Duration.zero));
      when(() => mockStream.buffer)
          .thenAnswer((_) => Stream.value(Duration.zero));
      when(() => mockStream.volume).thenAnswer((_) => Stream.value(100.0));
      when(() => mockStream.playlistMode)
          .thenAnswer((_) => Stream.value(PlaylistMode.none));
      when(() => mockStream.shuffle).thenAnswer((_) => Stream.value(false));

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
