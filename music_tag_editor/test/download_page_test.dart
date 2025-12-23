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

    when(() => mockDeps.ensureDependencies()).thenAnswer((_) async => {});
    when(() => mockDeps.areAllDependenciesInstalled())
        .thenAnswer((_) async => true);
  });

  Widget createTestWidget() {
    return const MaterialApp(home: DownloadPage());
  }

  group('DownloadPage', () {
    testWidgets('renders initial UI', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Download de Música'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows paste button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.paste), findsOneWidget);
    });

    testWidgets('has dropdown selector', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButton), findsWidgets);
    });

    testWidgets('button bar is present', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Buscar Info'), findsOneWidget);
    });

    testWidgets('url input accepts text', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextField).first, 'https://youtube.com/watch?v=test');
      await tester.pump();

      expect(find.text('https://youtube.com/watch?v=test'), findsOneWidget);
    });

    testWidgets('scaffold renders', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
