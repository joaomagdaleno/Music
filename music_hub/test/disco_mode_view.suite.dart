@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_hub/features/party_mode/disco_mode_screen.dart';

import 'package:music_hub/features/player/services/playback_service.dart';
import 'package:music_hub/core/services/theme_service.dart';
import 'package:music_hub/features/library/models/search_models.dart';

class MockPlaybackService extends Mock implements PlaybackService {}

class MockThemeService extends Mock implements ThemeService {}

void main() {
  late MockPlaybackService mockPlayback;
  late MockThemeService mockTheme;

  setUp(() {
    mockPlayback = MockPlaybackService();
    mockTheme = MockThemeService();

    PlaybackService.instance = mockPlayback;
    ThemeService.instance = mockTheme;

    when(() => mockTheme.primaryColor).thenReturn(Colors.purple);
    when(() => mockTheme.addListener(any())).thenReturn(null);
    when(() => mockTheme.removeListener(any())).thenReturn(null);
  });

  Widget createTestWidget() => MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const DiscoModeScreen(),
      );

  group('DiscoModeScreen', () {
    testWidgets('renders with no track playing', (tester) async {
      when(() => mockPlayback.currentTrack).thenReturn(null);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('No Track'), findsOneWidget);
      expect(find.text('Toque para sair'), findsOneWidget);
    });

    testWidgets('renders with track playing', (tester) async {
      final track = SearchResult(
        id: '1',
        title: 'Test Song',
        artist: 'Test Artist',
        url: 'http://test',
        platform: MediaPlatform.youtube,
        thumbnail: null,
      );
      when(() => mockPlayback.currentTrack).thenReturn(track);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Test Song'), findsOneWidget);
      expect(find.text('Test Artist'), findsOneWidget);
    });

    testWidgets('tap closes the view', (tester) async {
      when(() => mockPlayback.currentTrack).thenReturn(null);

      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DiscoModeScreen()),
            ),
            child: const Text('Open Disco'),
          ),
        ),
      ));

      await tester.tap(find.text('Open Disco'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DiscoModeScreen), findsOneWidget);

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DiscoModeScreen), findsNothing);
    });

    testWidgets('visualizer bars animate', (tester) async {
      when(() => mockPlayback.currentTrack).thenReturn(null);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // The bars should have been rendered
      expect(find.byType(AnimatedContainer), findsWidgets);
    });

    testWidgets('rotation animation runs', (tester) async {
      when(() => mockPlayback.currentTrack).thenReturn(null);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 500));

      // Check that Transform.rotate widgets exist
      expect(find.byType(Transform), findsWidgets);
    });
  });
}
