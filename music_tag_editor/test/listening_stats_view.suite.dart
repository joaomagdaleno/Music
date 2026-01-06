@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_hub/screens/stats/listening_stats_screen.dart';
import 'package:music_hub/services/listening_stats_service.dart';
import 'package:music_hub/core/services/theme_service.dart';

class MockListeningStatsService extends Mock implements ListeningStatsService {}

class MockThemeService extends Mock implements ThemeService {}

void main() {
  late MockListeningStatsService mockStats;
  late MockThemeService mockTheme;

  setUp(() {
    mockStats = MockListeningStatsService();
    mockTheme = MockThemeService();

    ListeningStatsService.instance = mockStats;
    ThemeService.instance = mockTheme;

    when(() => mockTheme.primaryColor).thenReturn(Colors.blue);
    when(() => mockTheme.addListener(any())).thenReturn(null);
    when(() => mockTheme.removeListener(any())).thenReturn(null);
  });

  Widget createTestWidget() => MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const Scaffold(body: ListeningStatsScreen()),
      );

  group('ListeningStatsScreen', () {
    testWidgets('renders all sections when data is available', (tester) async {
      final stats = ListeningStats(
        totalTracks: 10,
        totalPlays: 100,
        estimatedListeningTime: const Duration(hours: 5),
        topTracks: [
          {
            'title': 'Song A',
            'artist': 'Artist A',
            'play_count': 20,
            'thumbnail': null
          },
        ],
        topArtists: [
          const MapEntry('Artist A', 50),
        ],
        topGenres: [
          const MapEntry('Rock', 30),
        ],
      );

      when(() => mockStats.getStats()).thenAnswer((_) async => stats);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Initial load
      await tester.pump(); // FutureBuilder completion

      expect(find.text('Estatísticas de Escuta'), findsOneWidget);
      expect(find.text('5h 0min'), findsOneWidget);
      expect(find.text('Song A'), findsOneWidget);
      expect(find.text('Artist A'), findsWidgets);
    });

    testWidgets('shows loading state and clears timers', (tester) async {
      when(() => mockStats.getStats()).thenAnswer((_) => Future.delayed(
          const Duration(milliseconds: 100),
          () => ListeningStats(
              totalTracks: 0,
              totalPlays: 0,
              estimatedListeningTime: Duration.zero,
              topTracks: [],
              topArtists: [],
              topGenres: [])));

      await tester.pumpWidget(createTestWidget());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200)); // Clear the timer
    });
  });
}
