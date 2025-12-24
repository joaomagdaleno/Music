import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/services/backup_service.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:path/path.dart' as p;

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late MockDatabaseService mockDb;
  late BackupService service;
  late Directory tempDir;

  setUp(() async {
    mockDb = MockDatabaseService();
    DatabaseService.instance = mockDb;
    service = BackupService.instance;
    tempDir = await Directory.systemTemp.createTemp('backup_test_');

    // Default DB stubs
    when(() => mockDb.getTracks()).thenAnswer((_) async => []);
    when(() => mockDb.getPlaylists()).thenAnswer((_) async => []);
    when(() => mockDb.getPlayHistory()).thenAnswer((_) async => []);
    when(() => mockDb.getAllSettings()).thenAnswer((_) async => {});
    when(() => mockDb.saveTrack(any())).thenAnswer((_) async {});
    when(() => mockDb.savePlaylist(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BackupService', () {
    test('createBackup creates a zip file with data', () async {
      when(() => mockDb.getTracks()).thenAnswer((_) async => [
            {'id': '1', 'title': 'Test Track'}
          ]);

      final zipPath = await service.createBackup(tempDir.path);

      expect(File(zipPath).existsSync(), isTrue);
      expect(zipPath.endsWith('.zip'), isTrue);
      verify(() => mockDb.getTracks()).called(1);
    });

    test('restoreBackup restores data from zip', () async {
      // 1. Create a fake backup
      when(() => mockDb.getTracks()).thenAnswer((_) async => [
            {'id': 'restore_1', 'title': 'Restored Track'}
          ]);
      final zipPath = await service.createBackup(tempDir.path);

      // 2. Restore it
      final restoreCount = await service.restoreBackup(zipPath);

      expect(restoreCount, equals(1));
      verify(() => mockDb.saveTrack(any(that: containsPair('id', 'restore_1'))))
          .called(1);
    });

    test('estimateBackupSize returns valid size', () async {
      when(() => mockDb.getTracks()).thenAnswer((_) async => [
            {'id': '1', 'title': 'Test'}
          ]);

      final size = await service.estimateBackupSize();
      expect(size, greaterThan(0));
      verify(() => mockDb.getTracks()).called(1);
    });
  });
}
