import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:palette_generator_master/palette_generator_master.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

class MockPaletteGenerator extends Mock implements PaletteGeneratorMaster {}

void main() {
  late ThemeService service;
  late MockDatabaseService mockDb;

  setUp(() {
    mockDb = MockDatabaseService();
    DatabaseService.instance = mockDb;
    service = ThemeService.instance;
  });

  group('ThemeService', () {
    test('init loads settings from DB', () async {
      when(() => mockDb.getSetting('customColor'))
          .thenAnswer((_) async => null);
      when(() => mockDb.getSetting('useCustomColor'))
          .thenAnswer((_) async => 'false');

      await service.init();

      expect(service.useCustomColor, false);
    });

    test('setCustomColor saves to DB and updates state', () async {
      when(() => mockDb.saveSetting(any(), any())).thenAnswer((_) async {});

      await service.setCustomColor(Colors.red);

      expect(service.useCustomColor, true);
      expect(service.customColor, Colors.red);
      verify(() => mockDb.saveSetting('useCustomColor', 'true')).called(1);
    });
  });
}
