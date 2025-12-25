@Tags(['widget'])
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_tag_editor/views/karaoke_view.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/lyrics_service.dart';

class MockPlaybackService extends Mock implements PlaybackService {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

class MockLyricsService extends Mock implements LyricsService {}

void main() {
  late MockPlaybackService mockPlayback;
  late MockAudioPlayer mockPlayer;

  setUp(() {
    mockPlayback = MockPlaybackService();
    mockPlayer = MockAudioPlayer();

    PlaybackService.instance = mockPlayback;

    when(() => mockPlayback.player).thenReturn(mockPlayer);
    when(() => mockPlayer.position).thenReturn(Duration.zero);
    when(() => mockPlayback.currentLyrics).thenReturn([]);
    when(() => mockPlayback.lyricsStream).thenAnswer((_) => Stream.value([]));
    when(() => mockPlayback.resume()).thenAnswer((_) async => {});
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: KaraokeView(
        track: {'id': '1', 'title': 'Test Song', 'artist': 'Test Artist'},
      ),
    );
  }

  group('KaraokeView', () {
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
