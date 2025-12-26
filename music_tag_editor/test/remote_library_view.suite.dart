@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/views/remote_library_view.dart';
import 'package:music_tag_editor/services/local_duo_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/download_service.dart';

class MockLocalDuoService extends Mock implements LocalDuoService {}

class MockPlaybackService extends Mock implements PlaybackService {}

void main() {
  late MockLocalDuoService mockDuo;
  late MockPlaybackService mockPlayback;

  setUpAll(() {
    registerFallbackValue(SearchResult(
      id: 'fallback',
      title: 'Fallback',
      artist: 'Fallback',
      url: 'http://fallback',
      platform: MediaPlatform.youtube,
    ));
  });

  setUp(() {
    mockDuo = MockLocalDuoService();
    mockPlayback = MockPlaybackService();

    LocalDuoService.instance = mockDuo;
    PlaybackService.instance = mockPlayback;

    when(() => mockDuo.requestRemoteLibrary()).thenAnswer((_) async {});
    when(() => mockPlayback.playSearchResult(any())).thenAnswer((_) async {});
    when(() => mockPlayback.addToQueue(any())).thenAnswer((_) async {});
  });

  Widget createTestWidget() {
    return const MaterialApp(home: RemoteLibraryView());
  }

  group('RemoteLibraryView', () {
    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('has refresh button in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('displays correct app bar title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Biblioteca do Amigo'), findsOneWidget);
    });

    testWidgets('has scaffold', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
