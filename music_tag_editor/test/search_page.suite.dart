@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/views/search_page.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'test_helper.dart';

void main() {
  setUp(() async {
    await setupMusicTest();

    // Default DependencyManager behavior: success immediately
    when(() =>
            mockDeps.ensureDependencies(onProgress: any(named: 'onProgress')))
        .thenAnswer((invocation) async {
      final callback = invocation.namedArguments[#onProgress] as void Function(
          String, double)?;
      callback?.call('Done', 1.0);
    });
  });

  testWidgets('Shows initialization progress then content', (tester) async {
    // Simulate slow initialization
    when(() =>
            mockDeps.ensureDependencies(onProgress: any(named: 'onProgress')))
        .thenAnswer((invocation) async {
      final callback = invocation.namedArguments[#onProgress] as void Function(
          String, double)?;
      callback?.call('Loading...', 0.5);
      await Future.delayed(const Duration(milliseconds: 100));
      callback?.call('Done', 1.0);
    });

    await tester.pumpWidget(const MaterialApp(home: SearchPage()));
    await tester.pump(); // Start init

    expect(find.text('Loading...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100)); // Finish init
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Busca de Músicas'), findsOneWidget);
  });

  testWidgets('Performs search and displays results', (tester) async {
    final results = [
      SearchResult(
        id: '1',
        title: 'Song 1',
        artist: 'Artist 1',
        url: 'http://1',
        platform: MediaPlatform.youtube,
      ),
      SearchResult(
        id: '2',
        title: 'Song 2',
        artist: 'Artist 2',
        url: 'http://2',
        platform: MediaPlatform.spotify,
      ),
    ];

    when(() => mockSearch.searchAll(any(),
            onStatusUpdate: any(named: 'onStatusUpdate')))
        .thenAnswer((invocation) async {
      final callback = invocation.namedArguments[#onStatusUpdate] as void
          Function(MediaPlatform, SearchStatus)?;
      callback?.call(MediaPlatform.youtube, SearchStatus.completed);
      callback?.call(MediaPlatform.spotify, SearchStatus.completed);
      callback?.call(MediaPlatform.youtubeMusic, SearchStatus.completed);
      return results;
    });

    await tester.pumpWidget(const MaterialApp(home: SearchPage()));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.enterText(find.byType(TextField), 'test query');
    await tester.tap(find.text('Buscar'));
    await tester.pump();

    // Verify loading/searching state if needed, but here we just wait for results
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Song 1'), findsOneWidget);
    expect(find.text('Artist 1 • '), findsWidgets);
    expect(find.text('Song 2'), findsOneWidget);
  });

  testWidgets('Handles play track interaction', (tester) async {
    final result = SearchResult(
      id: '1',
      title: 'Song 1',
      artist: 'Artist 1',
      url: 'http://1',
      platform: MediaPlatform.youtube,
    );

    when(() => mockSearch.searchAll(any(),
            onStatusUpdate: any(named: 'onStatusUpdate')))
        .thenAnswer((invocation) async {
      final callback = invocation.namedArguments[#onStatusUpdate] as void
          Function(MediaPlatform, SearchStatus)?;
      callback?.call(MediaPlatform.youtube, SearchStatus.completed);
      callback?.call(MediaPlatform.spotify, SearchStatus.completed);
      callback?.call(MediaPlatform.youtubeMusic, SearchStatus.completed);
      return [result];
    });
    when(() => mockPlayback.playSearchResult(any()))
        .thenAnswer((_) async => Future.value());

    await tester.pumpWidget(const MaterialApp(home: SearchPage()));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.enterText(find.byType(TextField), 'test');
    await tester.tap(find.text('Buscar'));
    await tester.pump();
    await tester.pump(); // For status updates
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 100)); // Show SnackBar

    verify(() => mockPlayback.playSearchResult(result)).called(1);
    expect(find.text('Carregando áudio de "Song 1"...'), findsOneWidget);
  });

  testWidgets('Shows no results message', (tester) async {
    when(() => mockSearch.searchAll(any(),
            onStatusUpdate: any(named: 'onStatusUpdate')))
        .thenAnswer((invocation) async {
      final callback = invocation.namedArguments[#onStatusUpdate] as void
          Function(MediaPlatform, SearchStatus)?;
      callback?.call(MediaPlatform.youtube, SearchStatus.completed);
      callback?.call(MediaPlatform.spotify, SearchStatus.completed);
      callback?.call(MediaPlatform.youtubeMusic, SearchStatus.completed);
      return [];
    });

    await tester.pumpWidget(const MaterialApp(home: SearchPage()));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.enterText(find.byType(TextField), 'unknown');
    await tester.tap(find.text('Buscar'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Nenhuma música encontrada nas plataformas selecionadas.'),
        findsOneWidget);
  });

  testWidgets('Shows error message on initialization failure', (tester) async {
    when(() =>
            mockDeps.ensureDependencies(onProgress: any(named: 'onProgress')))
        .thenThrow('Init failed');

    await tester.pumpWidget(const MaterialApp(home: SearchPage()));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Erro ao inicializar: Init failed'),
        findsOneWidget);
  });
}
