@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/views/playlist_importer_view.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/download_service.dart';

class MockSearchService extends Mock implements SearchService {}

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late MockDatabaseService mockDb;

  setUpAll(() {
    registerFallbackValue(SearchResult(
      id: 'fallback',
      title: 'Fallback',
      artist: 'Fallback',
      url: 'http://fallback',
      platform: MediaPlatform.youtube,
    ));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockDb = MockDatabaseService();
    DatabaseService.instance = mockDb;

    when(() => mockDb.saveTrack(any())).thenAnswer((_) async {});
  });

  Widget createTestWidget() {
    return const MaterialApp(home: PlaylistImporterView());
  }

  group('PlaylistImporterView', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('has text field for URL', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('displays correct app bar title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Importador de Playlist'), findsOneWidget);
    });

    testWidgets('shows placeholder text', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Cole um link acima para escanear a playlist.'),
          findsOneWidget);
    });

    testWidgets('has download icon button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('text field accepts input', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.enterText(
          find.byType(TextField), 'https://spotify.com/playlist/123');
      await tester.pump();

      expect(find.text('https://spotify.com/playlist/123'), findsOneWidget);
    });
  });
}
