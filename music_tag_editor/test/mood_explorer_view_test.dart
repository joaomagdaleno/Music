import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/views/mood_explorer_view.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/download_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

class MockPlaybackService extends Mock implements PlaybackService {}

void main() {
  late MockDatabaseService mockDb;
  late MockPlaybackService mockPlayback;

  setUpAll(() {
    registerFallbackValue(SearchResult(
      id: 'fallback',
      title: 'Fallback',
      artist: 'Fallback',
      url: 'http://fallback',
      platform: MediaPlatform.youtube,
    ));
  });

  setUp(() {
    mockDb = MockDatabaseService();
    mockPlayback = MockPlaybackService();

    DatabaseService.instance = mockDb;
    PlaybackService.instance = mockPlayback;
  });

  Widget createTestWidget() {
    return MaterialApp(home: Scaffold(body: MoodExplorerView()));
  }

  group('MoodExplorerView', () {
    testWidgets('renders mood cards', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Qual o seu mood hoje?'), findsOneWidget);
      expect(find.text('Energético'), findsOneWidget);
      expect(find.text('Relaxante'), findsOneWidget);
      expect(find.text('Foco'), findsOneWidget);
      expect(find.text('Melancólico'), findsOneWidget);
    });

    testWidgets('tapping mood opens bottom sheet', (tester) async {
      when(() => mockDb.getTracksByMood(any())).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Energético'));
      await tester.pumpAndSettle();

      expect(find.text('Mix Energético'), findsOneWidget);
      expect(find.text('Nenhuma música encontrada para este mood.'),
          findsOneWidget);
    });

    testWidgets('mood sheet shows loading indicator', (tester) async {
      when(() => mockDb.getTracksByMood(any())).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 500));
        return [];
      });

      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Relaxante'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('grid layout displays correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(InkWell), findsNWidgets(4));
    });

    testWidgets('mood icons are displayed', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byIcon(Icons.flash_on), findsOneWidget);
      expect(find.byIcon(Icons.spa), findsOneWidget);
      expect(find.byIcon(Icons.center_focus_strong), findsOneWidget);
      expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
    });
  });
}
