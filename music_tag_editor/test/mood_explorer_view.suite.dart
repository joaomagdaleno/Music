@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/screens/library/mood_explorer_screen.dart';
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

    // Default stubs
    when(() => mockDb.getTracks()).thenAnswer((_) async => []);
    when(() => mockDb.getTracksByMood(any())).thenAnswer((_) async => []);
  });

  Widget createTestWidget() => MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const Scaffold(body: MoodExplorerScreen()),
      );

  group('MoodExplorerScreen', () {
    testWidgets('renders mood sections', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Explorar por Humor'), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      when(() => mockDb.getTracks()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 500));
        return [];
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('displays empty state message', (tester) async {
      when(() => mockDb.getTracks()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma música analisada ainda.'), findsOneWidget);
    });
  });
}
