@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/views/download_page.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';

class MockDownloadService extends Mock implements DownloadService {}

class MockDependencyManager extends Mock implements DependencyManager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDownloadService mockDownload;
  late MockDependencyManager mockDeps;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://test'));
    registerFallbackValue(SearchResult(
      id: 'fallback',
      title: 'Fallback',
      artist: 'Fallback',
      url: 'http://fallback',
      platform: MediaPlatform.youtube,
    ));
  });

  setUp(() {
    mockDownload = MockDownloadService();
    mockDeps = MockDependencyManager();

    DownloadService.instance = mockDownload;
    DependencyManager.instance = mockDeps;

    when(() => mockDownload.detectPlatform(any()))
        .thenReturn(MediaPlatform.unknown);

    when(() =>
            mockDeps.ensureDependencies(onProgress: any(named: 'onProgress')))
        .thenAnswer((_) async => {});
    when(() => mockDeps.areAllDependenciesInstalled())
        .thenAnswer((_) async => true);
  });

  Widget createTestWidget() {
    return const MaterialApp(home: DownloadPage());
  }

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
