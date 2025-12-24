import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/services/persona_service.dart';
import 'package:music_tag_editor/models/persona_model.dart';
import 'package:music_tag_editor/services/database_service.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late MockDatabaseService mockDb;

  setUp(() {
    mockDb = MockDatabaseService();
    DatabaseService.instance = mockDb;

    when(() => mockDb.getSetting(any())).thenAnswer((_) async => null);
    when(() => mockDb.saveSetting(any(), any())).thenAnswer((_) async {});
  });

  group('PersonaService Unit Tests', () {
    test('Default persona should be listener', () {
      expect(PersonaService.instance.activePersona, AppPersona.listener);
    });

    test('setPersona updates activePersona and notifies listeners', () {
      bool notified = false;
      PersonaService.instance.addListener(() {
        notified = true;
      });

      PersonaService.instance.setPersona(AppPersona.librarian);

      expect(PersonaService.instance.activePersona, AppPersona.librarian);
      expect(notified, isTrue);

      verify(() => mockDb.saveSetting('active_persona', 'librarian')).called(1);

      // Reset to default for other tests
      PersonaService.instance.setPersona(AppPersona.listener);
    });
  });
}
