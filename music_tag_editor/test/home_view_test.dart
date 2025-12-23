import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/views/home_view.dart';
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
    return const MaterialApp(home: HomeView());
  }

  group('HomeView', () {
    testWidgets('renders greeting', (tester) async {
      when(() => mockDb.getRecentlyPlayed()).thenAnswer((_) async => []);
      when(() => mockDb.getAllTracks()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('renders smart library cards', (tester) async {
      when(() => mockDb.getRecentlyPlayed()).thenAnswer((_) async => []);
      when(() => mockDb.getAllTracks()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
    });

    testWidgets('renders moods section', (tester) async {
      when(() => mockDb.getRecentlyPlayed()).thenAnswer((_) async => []);
      when(() => mockDb.getAllTracks()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.flash_on), findsWidgets);
      expect(find.byIcon(Icons.spa), findsWidgets);
    });

    testWidgets('renders disco mode button', (tester) async {
      when(() => mockDb.getRecentlyPlayed()).thenAnswer((_) async => []);
      when(() => mockDb.getAllTracks()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.nightlife), findsOneWidget);
    });

    testWidgets('renders recents list with tracks', (tester) async {
      when(() => mockDb.getRecentlyPlayed()).thenAnswer((_) async => [
            {
              'id': '1',
              'title': 'Recent Song',
              'artist': 'Artist Name',
              'url': 'http://test',
              'platform': 'MediaPlatform.youtube'
            },
          ]);
      when(() => mockDb.getAllTracks()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Recent Song'), findsOneWidget);
    });

    testWidgets('scaffold renders correctly', (tester) async {
      when(() => mockDb.getRecentlyPlayed()).thenAnswer((_) async => []);
      when(() => mockDb.getAllTracks()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
