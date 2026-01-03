@Tags(['widget'])
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:media_kit/media_kit.dart';
import 'package:music_tag_editor/screens/disco/karaoke_screen.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/lyrics_service.dart';
import 'test_helper.dart';

class MockPlaybackService extends Mock implements PlaybackService {}

class MockLyricsService extends Mock implements LyricsService {}

void main() {
  late MockPlaybackService mockPlayback;
  late MockPlayer mockPlayer;

  setUp(() async {
    await setupMusicTest();
    mockPlayback = MockPlaybackService();
    // mockLyrics = MockLyricsService(); // Removed as unused
    mockPlayer = MockPlayer(); // Or used global? setupMusicTest provides global mockPlayer.
    // Use the global one or local if needed.
    // If we use local, we shadow global. Let's use local for safety within suite if it was using local.
    // Actually, to avoid conflicts, just use the global one if possible?
    // But suite declares `late MockAudioPlayer mockPlayer;`.
    // I'll reuse the variable name `mockPlayer` but type `MockPlayer`.


    PlaybackService.instance = mockPlayback;

    when(() => mockPlayback.player).thenReturn(mockPlayer);
    // Stub position if needed, or removing if test doesn't use it.
    // when(() => mockPlayer.state.position).thenReturn(Duration.zero);
    // But better toStub state:
    when(() => mockPlayer.state).thenReturn(PlayerState(position: Duration.zero));

    when(() => mockPlayback.currentLyrics).thenReturn([]);
    when(() => mockPlayback.lyricsStream).thenAnswer((_) => Stream.value([]));
    when(() => mockPlayback.resume()).thenAnswer((_) async => {});
  });

  Widget createTestWidget() {
    return MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: KaraokeScreen(
        track: const {'id': '1', 'title': 'Test Song', 'artist': 'Test Artist'},
      ),
    );
  }

  group('KaraokeScreen', () {
    testWidgets('renders track title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Test Song'), findsOneWidget);
      expect(find.text('Test Artist'), findsOneWidget);
    });

    testWidgets('renders close button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows no lyrics message when empty', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Letras não sincronizadas...'), findsOneWidget);
    });

    testWidgets('renders play button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.play_circle_filled), findsOneWidget);
    });

    testWidgets('scaffold has black background', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.black));
    });

    testWidgets('tapping play button calls resume', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.play_circle_filled));
      await tester.pump();

      verify(() => mockPlayback.resume()).called(1);
    });
  });
}
