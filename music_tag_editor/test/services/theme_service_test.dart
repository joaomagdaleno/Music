@Tags(['unit'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:palette_generator_master/palette_generator_master.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

class FakePaletteColor extends Fake implements PaletteColorMaster {
  @override
  final Color color;
  FakePaletteColor(this.color);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FakePaletteColor($color)';
  }
}

class FakePaletteGenerator extends Fake implements PaletteGeneratorMaster {
  final Map<String, PaletteColorMaster> _colors;
  FakePaletteGenerator(this._colors);

  @override
  PaletteColorMaster? get dominantColor => _colors['dominant'];

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FakePaletteGenerator';
  }
}

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

    test('updateThemeFromImage updates primary color from palette', () async {
      // Reset singleton state from previous test
      when(() => mockDb.saveSetting(any(), any())).thenAnswer((_) async {});
      await service.setAutoMode();

      // Mock the generator function
      service.paletteGenerator = (image,
          {int? maximumColorCount,
          Size? size,
          Rect? region,
          List<PaletteFilterMaster>? filters,
          List<PaletteTargetMaster>? targets}) async {
        return FakePaletteGenerator(
            {'dominant': FakePaletteColor(Colors.green)});
      };

      await service.updateThemeFromImage('http://test.com/image.jpg');

      expect(service.primaryColor, Colors.green);
    });
  });
}
