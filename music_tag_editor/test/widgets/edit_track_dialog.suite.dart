@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_hub/models/search_models.dart';
import 'package:music_hub/widgets/edit_track_dialog.dart';

void main() {
  testWidgets('EditTrackDialog renders properly and returns updated track',
      (tester) async {
    final track = SearchResult(
      id: 'test_id',
      title: 'Original Title',
      artist: 'Original Artist',
      album: 'Original Album',
      url: 'https://youtube.com/watch?v=test_id',
      platform: MediaPlatform.youtube,
    );

    SearchResult? result;

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(platform: TargetPlatform.android),
      home: Builder(
          builder: (context) => TextButton(
                onPressed: () async {
                  result = await showDialog<SearchResult>(
                    context: context,
                    builder: (_) => EditTrackDialog(track: track),
                  );
                },
                child: const Text('Edit'),
              )),
    ));

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.byType(EditTrackDialog), findsOneWidget);
    expect(find.text('Original Title'), findsOneWidget);

    // Edit Title
    await tester.enterText(
        find.widgetWithText(TextField, 'Title'), 'New Title');
    await tester.enterText(
        find.widgetWithText(TextField, 'Artist'), 'New Artist');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(EditTrackDialog), findsNothing);
    expect(result, isNotNull);
    expect(result!.title, 'New Title');
    expect(result!.artist, 'New Artist');
    expect(result!.album, 'Original Album'); // Unchanged
  });
}
