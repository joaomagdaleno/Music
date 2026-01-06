import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_hub/models/search_models.dart';
import 'package:music_hub/features/library/models/metadata_models.dart';
import 'package:music_hub/features/library/screens/tag_editor_screen.dart';
import 'package:music_hub/features/library/services/metadata_aggregator_service.dart';
import 'package:music_hub/core/services/database_service.dart';

class MockMetadataService extends Mock implements MetadataAggregatorService {}
class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late MockMetadataService mockMetadataService;
  late MockDatabaseService mockDatabaseService;
  late SearchResult testTrack;

  setUp(() {
    mockMetadataService = MockMetadataService();
    mockDatabaseService = MockDatabaseService();
    MetadataAggregatorService.instance = mockMetadataService;
    DatabaseService.instance = mockDatabaseService;

    testTrack = SearchResult(
      id: '123',
      title: 'Original Title',
      artist: 'Original Artist',
      url: 'https://example.com',
      platform: MediaPlatform.youtube,
    );

    // Default mock behavior
    when(() => mockMetadataService.aggregateMetadata(any(), any()))
        .thenAnswer((_) async => AggregatedMetadata(
              title: 'New Title',
              artist: 'New Artist',
              album: 'New Album',
              allGenres: ['Pop', 'Rock'],
              year: 2024,
            ));
  });

  Widget createTestableWidget(Widget child) {
    return MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: child,
    );
  }

  testWidgets('TagEditorScreen shows original metadata', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(TagEditorScreen(track: testTrack)));

    // On Material, title is in AppBar and potentially an EditableText/TextField
    expect(find.text('Original Title'), findsAtLeastNWidgets(1));
    expect(find.text('Original Artist'), findsOneWidget);
  });

  testWidgets('Auto-fill updates controllers with mock data', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(TagEditorScreen(track: testTrack)));

    // Find and tap Auto-fill button (Material icon auto_awesome)
    final autoFillBtn = find.byIcon(Icons.auto_awesome);
    expect(autoFillBtn, findsOneWidget);
    await tester.tap(autoFillBtn);
    await tester.pumpAndSettle();

    verify(() => mockMetadataService.aggregateMetadata('Original Title', 'Original Artist')).called(1);

    expect(find.text('New Title'), findsOneWidget);
    expect(find.text('New Artist'), findsOneWidget);
    expect(find.text('New Album'), findsOneWidget);
    expect(find.text('Pop, Rock'), findsOneWidget);
    expect(find.text('2024'), findsOneWidget);
  });

  testWidgets('Save button is disabled when title is empty', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(TagEditorScreen(track: testTrack)));

    // Find the save button IconButton
    final saveBtnFinder = find.ancestor(
      of: find.byIcon(Icons.save),
      matching: find.byType(IconButton),
    );
    
    expect(tester.widget<IconButton>(saveBtnFinder).onPressed, isNotNull);

    // Clear title
    final titleField = find.widgetWithText(TextField, 'Title');
    await tester.enterText(titleField, '');
    await tester.pump();

    // Verify button is disabled
    expect(tester.widget<IconButton>(saveBtnFinder).onPressed, isNull);
  });
}
