@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/views/playlists_view.dart';
import 'package:music_tag_editor/services/database_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late MockDatabaseService mockDb;

  setUp(() {
    mockDb = MockDatabaseService();
    DatabaseService.instance = mockDb;
  });

  Widget createTestWidget() {
    return const MaterialApp(home: PlaylistsView());
  }

  group('PlaylistsView', () {
    testWidgets('renders empty state', (tester) async {
      when(() => mockDb.getPlaylists()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Você ainda não tem playlists.'), findsOneWidget);
      expect(find.text('Playlists'), findsOneWidget);
    });

    testWidgets('renders playlists list', (tester) async {
      when(() => mockDb.getPlaylists()).thenAnswer((_) async => [
            {'id': 1, 'name': 'Favoritas', 'description': 'Minhas favoritas'},
            {
              'id': 2,
              'name': 'Para correr',
              'description': 'Músicas para treino'
            },
          ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.text('Favoritas'), findsOneWidget);
      expect(find.text('Para correr'), findsOneWidget);
      expect(find.text('Minhas favoritas'), findsOneWidget);
      expect(find.text('Músicas para treino'), findsOneWidget);
    });

    testWidgets('shows FAB for creating playlists', (tester) async {
      when(() => mockDb.getPlaylists()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('FAB opens create playlist dialog', (tester) async {
      when(() => mockDb.getPlaylists()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Nova Playlist'), findsOneWidget);
      expect(find.text('Criar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('cancel dialog closes without creating', (tester) async {
      when(() => mockDb.getPlaylists()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      verifyNever(() => mockDb.createPlaylist(any()));
    });

    testWidgets('playlist items have correct icons', (tester) async {
      when(() => mockDb.getPlaylists()).thenAnswer((_) async => [
            {'id': 1, 'name': 'Test', 'description': 'Test playlist'},
          ]);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byIcon(Icons.playlist_play), findsOneWidget);
    });

    testWidgets('app bar renders correctly', (tester) async {
      when(() => mockDb.getPlaylists()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
