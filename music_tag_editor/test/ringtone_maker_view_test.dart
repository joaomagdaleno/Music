import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/views/ringtone_maker_view.dart';
import 'package:music_tag_editor/services/download_service.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(SearchResult(
      id: 'fallback',
      title: 'Fallback',
      artist: 'Fallback',
      url: 'http://fallback',
      platform: MediaPlatform.youtube,
    ));
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: RingtoneMakerView(
        track: SearchResult(
          id: '1',
          title: 'Test Song',
          artist: 'Test Artist',
          url: 'http://test.mp3',
          platform: MediaPlatform.youtube,
          localPath: null,
        ),
      ),
    );
  }

  group('RingtoneMakerView', () {
    testWidgets('renders Scaffold', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('displays track title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Test Song'), findsWidgets);
    });

    testWidgets('has play/pause button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.play_arrow), findsWidgets);
    });

    testWidgets('has app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Criador de Toques'), findsOneWidget);
    });
  });
}
