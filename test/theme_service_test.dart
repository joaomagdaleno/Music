import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_player/theme_service.dart';
import 'package:music_player/database_service.dart';
import 'package:palette_generator_master/palette_generator_master.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

class MockPaletteGeneratorMaster extends Mock
    implements PaletteGeneratorMaster {
  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      super.toString();
}

void main() {
  group('ThemeService Tests', () {
    late ThemeService themeService;
    late MockDatabaseService mockDb;

    setUp(() {
      mockDb = MockDatabaseService();
      DatabaseService.instance = mockDb;
      themeService = ThemeService.instance;

      when(() => mockDb.getSetting(any())).thenAnswer((_) async => null);
      when(() => mockDb.saveSetting(any(), any()))
          .thenAnswer((_) async => Future.value());

      // Reset state
      themeService.setAutoMode();
    });

    test('Initial color is blue', () {
      expect(themeService.primaryColor, Colors.blue);
    });

    test('setCustomColor updates color and saves to DB', () async {
      final color = Colors.red;
      await themeService.setCustomColor(color);

      expect(themeService.primaryColor, color);
      expect(themeService.useCustomColor, true);
      verify(() =>
              mockDb.saveSetting('customColor', color.toARGB32().toString()))
          .called(1);
    });

    test('updateThemeFromImage extracts color from palette', () async {
      final mockPalette = MockPaletteGeneratorMaster();
      final mockPaletteColor = PaletteColorMaster(Colors.green, 100);

      when(() => mockPalette.dominantColor).thenReturn(mockPaletteColor);

      themeService.paletteGenerator = (
        image, {
        maximumColorCount = 10,
        Size? size,
        Rect? region,
        List<PaletteFilterMaster>? filters,
        List<PaletteTargetMaster>? targets,
      }) async {
        return mockPalette;
      };

      await themeService.updateThemeFromImage('https://example.com/image.jpg');

      expect(themeService.primaryColor, Colors.green);
    });

    test('updateThemeFromImage handles error by falling back to blue',
        () async {
      themeService.paletteGenerator = (
        image, {
        maximumColorCount = 10,
        Size? size,
        Rect? region,
        List<PaletteFilterMaster>? filters,
        List<PaletteTargetMaster>? targets,
      }) async {
        throw Exception('Extraction failed');
      };

      await themeService.updateThemeFromImage('https://example.com/image.jpg');

      expect(themeService.primaryColor, Colors.blue);
    });
  });
}
