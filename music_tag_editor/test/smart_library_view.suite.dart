@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/screens/library/smart_library_screen.dart';
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

    when(() => mockDb.getMostPlayed()).thenAnswer((_) async => []);
    when(() => mockDb.getRecentlyPlayed()).thenAnswer((_) async => []);
  });

  Widget createTestWidget() => MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const Scaffold(body: SmartLibraryScreen()),
      );

  group('SmartLibraryScreen', () {
    testWidgets('renders tab bar', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Top Hits'), findsOneWidget);
      expect(find.text('Recentes'), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      // Simulate a long-running future for the active tab (Top Hits)
      when(() => mockDb.getMostPlayed()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 2));
        return [];
      });

      await tester.pumpWidget(createTestWidget());

      // Pump a single frame to start the FutureBuilder but not finish the delay
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Finish the future
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    });

    testWidgets('shows empty top hits message', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('Dê o play'), findsOneWidget);
    });

    testWidgets('shows top hits list', (tester) async {
      when(() => mockDb.getMostPlayed()).thenAnswer((_) async => [
            {
              'id': '1',
              'title': 'Top Song',
              'artist': 'Artist',
              'url': 'http://test',
              'platform': 'MediaPlatform.youtube',
              'play_count': 50
            },
          ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Top Song'), findsOneWidget);
      expect(find.text('Artist'), findsOneWidget);
    });
  });
}
