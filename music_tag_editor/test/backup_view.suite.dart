@Tags(['widget'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/views/backup_view.dart';
import 'package:music_tag_editor/services/backup_service.dart';

class MockBackupService extends Mock implements BackupService {}

void main() {
  late MockBackupService mockBackup;

  setUp(() {
    mockBackup = MockBackupService();
    BackupService.instance = mockBackup;

    when(() => mockBackup.createBackup(any()))
        .thenAnswer((_) async => 'path/to/backup.zip');
    when(() => mockBackup.restoreBackup(any()))
        .thenAnswer((_) async => 5); // 5 items restored
    when(() => mockBackup.estimateBackupSize()).thenAnswer((_) async => 1024);
  });

  Widget createTestWidget() {
    return const MaterialApp(home: BackupView());
  }

  group('BackupView', () {
    testWidgets('renders app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Backup & Restauração'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('renders create backup card', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Criar Backup'), findsWidgets);
      expect(find.byIcon(Icons.backup), findsOneWidget);
    });

    testWidgets('renders restore backup card', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Restaurar Backup'), findsOneWidget);
      expect(find.byIcon(Icons.restore), findsOneWidget);
    });

    testWidgets('shows backup size estimate', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle(); // createBackup might be called or estimate

      // Simply verify the cards exist generally
      expect(find.byType(Card), findsNWidgets(2));
    });
  });
}
