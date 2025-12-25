@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:music_tag_editor/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'test_helper.dart';

void main() {
  setUp(() async => await setupMusicTest(mockThemeInstance: false));

  group('ThemeService', () {
    test('instance is accessible', () {
      expect(ThemeService.instance, isNotNull);
    });

    test('primaryColor returns a Color', () {
      final color = ThemeService.instance.primaryColor;
      expect(color, isA<Color>());
    });

    test('setCustomColor updates color', () async {
      // Note: ThemeService.setCustomColor calls DatabaseService.instance.saveSetting
      // setupMusicTest mocks DatabaseService by default, so this should work.
      await ThemeService.instance.setCustomColor(Colors.red);
      expect(ThemeService.instance.primaryColor, equals(Colors.red));
    });

    test('ThemeService is a ChangeNotifier', () {
      expect(ThemeService.instance, isA<ChangeNotifier>());
    });
  });
}
