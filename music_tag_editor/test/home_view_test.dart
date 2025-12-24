@Tags(['widget'])
library;

import 'dart:async';
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
      final completer = Completer<List<Map<String, dynamic>>>();
      when(() => mockDb.getRecentlyPlayed()).thenAnswer((_) async => []);
      when(() => mockDb.getTracks()).thenAnswer((_) => completer.future);
      when(() => mockDb.getAllTracks()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Show loading

      completer.complete([]);
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('renders smart library cards', (tester) async {
      final completer = Completer<List<Map<String, dynamic>>>();
      when(() => mockDb.getRecentlyPlayed()).thenAnswer((_) async => []);
      when(() => mockDb.getTracks()).thenAnswer((_) => completer.future);
      when(() => mockDb.getAllTracks()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      completer.complete([]);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
    });

    testWidgets('renders moods section', (tester) async {
      final completer = Completer<List<Map<String, dynamic>>>();
      when(() => mockDb.getRecentlyPlayed()).thenAnswer((_) async => []);
      when(() => mockDb.getTracks()).thenAnswer((_) => completer.future);
      when(() => mockDb.getAllTracks()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      completer.complete([]);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.center_focus_strong), findsWidgets);
      expect(find.byIcon(Icons.fitness_center), findsWidgets);
    });

    testWidgets('renders disco mode button', (tester) async {
      final completer = Completer<List<Map<String, dynamic>>>();
      when(() => mockDb.getRecentlyPlayed()).thenAnswer((_) async => []);
      when(() => mockDb.getTracks()).thenAnswer((_) => completer.future);
      when(() => mockDb.getAllTracks()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      completer.complete([]);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('renders recents list with tracks', (tester) async {
      final completer = Completer<List<Map<String, dynamic>>>();
      when(() => mockDb.getRecentlyPlayed()).thenAnswer((_) async => []);
      when(() => mockDb.getTracks()).thenAnswer((_) => completer.future);
      when(() => mockDb.getAllTracks()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      completer.complete([
        {
          'id': '1',
          'title': 'Recent Song',
          'artist': 'Artist Name',
          'url': 'http://test',
          'platform': 'MediaPlatform.youtube'
        },
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Recent Song'), findsOneWidget);
    });

    testWidgets('scaffold renders correctly', (tester) async {
      final completer = Completer<List<Map<String, dynamic>>>();
      when(() => mockDb.getRecentlyPlayed()).thenAnswer((_) async => []);
      when(() => mockDb.getTracks()).thenAnswer((_) => completer.future);
      when(() => mockDb.getAllTracks()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      completer.complete([]);
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
