@Tags(['widget'])
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_hub/features/library/screens/my_tracks_screen.dart';

import 'test_helper.dart';

void main() {
  setUp(() async {
    await setupMusicTest();
  });

  Widget createTestWidget() => MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const Scaffold(body: MyTracksScreen()),
      );

  group('MyTracksScreen', () {
    testWidgets('renders loading state', (tester) async {
      final completer = Completer<List<Map<String, dynamic>>>();
      when(() => mockDb.getTracks()).thenAnswer((_) => completer.future);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the future to clean up
      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('renders empty state', (tester) async {
      when(() => mockDb.getTracks()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma música na biblioteca.'), findsOneWidget);
    });

    testWidgets('renders tracks list', (tester) async {
      when(() => mockDb.getTracks()).thenAnswer((_) async => [
            {
              'id': '1',
              'title': 'Track 1',
              'artist': 'Artist 1',
              'url': 'http://test',
              'platform': 'MediaPlatform.youtube'
            },
            {
              'id': '2',
              'title': 'Track 2',
              'artist': 'Artist 2',
              'url': 'http://test',
              'platform': 'MediaPlatform.youtube'
            },
          ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Track 1'), findsOneWidget);
      expect(find.text('Track 2'), findsOneWidget);
      expect(find.text('Artist 1'), findsOneWidget);
      expect(find.text('Artist 2'), findsOneWidget);
    });

    testWidgets('shows menu button for each track', (tester) async {
      when(() => mockDb.getTracks()).thenAnswer((_) async => [
            {
              'id': '1',
              'title': 'Track 1',
              'artist': 'Artist 1',
              'url': 'http://test',
              'platform': 'MediaPlatform.youtube'
            },
          ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.security), findsOneWidget);
    });
    testWidgets('has menu button for vault actions', (tester) async {
      when(() => mockDb.getTracks()).thenAnswer((_) async => [
            {
              'id': '1',
              'title': 'Track 1',
              'artist': 'Artist 1',
              'url': 'http://test',
              'platform': 'MediaPlatform.youtube'
            },
          ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.security), findsOneWidget);
    });
  });
}
