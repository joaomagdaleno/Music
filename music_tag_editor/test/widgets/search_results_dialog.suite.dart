@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_tag_editor/widgets/search_results_dialog.dart';

void main() {
  testWidgets('SearchResultsDialog renders list and returns selection',
      (tester) async {
    final recordings = [
      {
        'title': 'Track 1',
        'artist-credit': [
          {'name': 'Artist 1'}
        ],
      },
      {
        'title': 'Track 2',
        'artist-credit': [
          {'name': 'Artist 2'}
        ],
      },
    ];

    dynamic selectedRecording;

    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return TextButton(
          onPressed: () async {
            selectedRecording = await showDialog(
              context: context,
              builder: (_) => SearchResultsDialog(recordings: recordings),
            );
          },
          child: const Text('Show Dialog'),
        );
      }),
    ));

    await tester.tap(find.text('Show Dialog'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SearchResultsDialog), findsOneWidget);
    expect(find.text('Track 1'), findsOneWidget);
    expect(find.text('Artist 1'), findsOneWidget);
    expect(find.text('Track 2'), findsOneWidget);

    // Select the first item
    await tester.tap(find.text('Track 1'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SearchResultsDialog), findsNothing);
    expect(selectedRecording, equals(recordings[0]));
  });

  testWidgets('SearchResultsDialog cancels correctly', (tester) async {
    final recordings = [];
    dynamic result;

    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        return TextButton(
          onPressed: () async {
            result = await showDialog(
              context: context,
              builder: (_) => SearchResultsDialog(recordings: recordings),
            );
          },
          child: const Text('Show Dialog'),
        );
      }),
    ));

    await tester.tap(find.text('Show Dialog'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Cancel'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SearchResultsDialog), findsNothing);
    expect(result, isNull);
  });
}
