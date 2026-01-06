@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_hub/views/download_page.dart';
import 'package:music_hub/models/download_models.dart';
import 'package:music_hub/models/search_models.dart';
import 'test_helper.dart';

void main() {
  setUp(() async {
    await setupMusicTest();

    // mockDownload.detectPlatform is static, no stub needed

    when(() =>
            mockDeps.ensureDependencies(onProgress: any(named: 'onProgress')))
        .thenAnswer((invocation) async {
      final callback = invocation.namedArguments[#onProgress] as void Function(
          String, double)?;
      callback?.call('Done', 1.0);
    });
  });

  Widget createTestWidget() => MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: const DownloadPage(),
      );

  group('DownloadPage', () {
    testWidgets('renders initial UI', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Download de Música'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows paste button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byIcon(Icons.paste), findsOneWidget);
    });

    testWidgets('has dropdown selector after search', (tester) async {
      when(() => mockDownload.getMediaInfo(any()))
          .thenAnswer((_) async => MediaInfo(
                title: 'Test Song',
                artist: 'Test Artist',
                platform: MediaPlatform.youtube,
                url: 'http://test.com',
                formats: [
                  DownloadFormat(
                    formatId: '1',
                    extension: 'mp3',
                    quality: '320kbps',
                    isAudioOnly: true,
                  ),
                ],
              ));

      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 200));

      await tester.enterText(
          find.byType(TextField), 'https://youtube.com/watch?v=test');
      await tester.tap(find.text('Buscar Info'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(
          find.byType(DropdownButtonFormField<DownloadFormat>), findsOneWidget);
    });

    testWidgets('button bar is present', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Buscar Info'), findsOneWidget);
    });

    testWidgets('url input accepts text', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 200));

      await tester.enterText(
          find.byType(TextField).first, 'https://youtube.com/watch?v=test');
      await tester.pump();

      expect(find.text('https://youtube.com/watch?v=test'), findsOneWidget);
    });

    testWidgets('scaffold renders', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
