@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/screens/playlists/playlist_importer_screen.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/models/search_models.dart';

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

  Widget createTestWidget() =>
      const MaterialApp(home: PlaylistImporterScreen());

  group('PlaylistImporterScreen', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Importador de Playlist'), findsOneWidget);
    });

    testWidgets('has text field for URL', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('URL da Playlist'), findsOneWidget);
    });

    testWidgets('shows placeholder text', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.text('Cole um link para começar.'), findsOneWidget);
    });

    testWidgets('has scan icon button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('text field accepts input', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.enterText(find.byType(TextField), 'https://test.com');
      await tester.pump();
      expect(find.text('https://test.com'), findsOneWidget);
    });
  });
}
