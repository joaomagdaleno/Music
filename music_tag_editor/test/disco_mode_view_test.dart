import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/views/disco_mode_view.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:music_tag_editor/services/download_service.dart';

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

  Widget createTestWidget() {
    return const MaterialApp(home: DiscoModeView());
  }

  group('DiscoModeView', () {
    testWidgets('renders with no track playing', (tester) async {
      when(() => mockPlayback.currentTrack).thenReturn(null);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('No Track Playing'), findsOneWidget);
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
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DiscoModeView()),
            ),
            child: const Text('Open Disco'),
          ),
        ),
      ));

      await tester.tap(find.text('Open Disco'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DiscoModeView), findsOneWidget);

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DiscoModeView), findsNothing);
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
