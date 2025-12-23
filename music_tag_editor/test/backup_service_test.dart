import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/services/backup_service.dart';
import 'package:music_tag_editor/services/database_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late MockDatabaseService mockDb;

  setUp(() {
    mockDb = MockDatabaseService();
    DatabaseService.instance = mockDb;
  });

  group('BackupService', () {
    test('instance is accessible', () {
      expect(BackupService.instance, isNotNull);
    });

    test('estimateBackupSize returns int', () async {
      when(() => mockDb.getTracks()).thenAnswer((_) async => []);
      when(() => mockDb.getPlaylists()).thenAnswer((_) async => []);

      final size = await BackupService.instance.estimateBackupSize();
      expect(size, isA<int>());
      expect(size, greaterThanOrEqualTo(0));
    });

    test('estimateBackupSize increases with data', () async {
      when(() => mockDb.getTracks()).thenAnswer((_) async => [
            {'id': '1', 'title': 'Song 1', 'artist': 'Artist'},
            {'id': '2', 'title': 'Song 2', 'artist': 'Artist'},
          ]);
      when(() => mockDb.getPlaylists()).thenAnswer((_) async => [
            {'id': 1, 'name': 'Playlist 1'},
          ]);

      final size = await BackupService.instance.estimateBackupSize();
      expect(size, greaterThan(10));
    });
  });
}
