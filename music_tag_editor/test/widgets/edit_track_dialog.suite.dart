@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_tag_editor/models/music_track.dart';
import 'package:music_tag_editor/widgets/edit_track_dialog.dart';

void main() {
  testWidgets('EditTrackDialog renders properly and returns updated track',
      (tester) async {
    final track = MusicTrack(
      filePath: '/path/to/file.mp3',
      title: 'Original Title',
      artist: 'Original Artist',
      album: 'Original Album',
      trackNumber: 1,
    );

    MusicTrack? result;

    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return TextButton(
          onPressed: () async {
            result = await showDialog<MusicTrack>(
              context: context,
              builder: (_) => EditTrackDialog(track: track),
            );
          },
          child: const Text('Edit'),
        );
      }),
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
    expect(result!.trackNumber, 1);
  });
}
