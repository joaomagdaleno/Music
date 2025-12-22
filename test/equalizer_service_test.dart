import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:music_player/equalizer_service.dart';

void main() {
  group('EqualizerService Tests', () {
    late EqualizerService equalizerService;

    setUp(() {
      equalizerService = EqualizerService.instance;
      // Reset state if needed
      equalizerService.setAutoMode(true);
      equalizerService.setNormalization(false);
      equalizerService.setTargetLoudness(-14.0);
    });

    test('Normalization calculation', () {
      equalizerService.setNormalization(true);
      equalizerService.setTargetLoudness(-14.0);

      // Same as target
      expect(equalizerService.calculateNormalizedVolume(-14.0), 1.0);

      // Track is louder (-10) than target (-14) -> adjustment -4
      // adjustment = -14 - (-10) = -4
      final vol = equalizerService.calculateNormalizedVolume(-10.0);
      expect(vol, closeTo(math.pow(10.0, -4 / 20.0), 0.001));
    });

    test('Normalization disabled returns 1.0', () {
      equalizerService.setNormalization(false);
      expect(equalizerService.calculateNormalizedVolume(-10.0), 1.0);
    });

    test('Auto mode state', () {
      equalizerService.setAutoMode(false);
      expect(equalizerService.isAutoMode, false);
      equalizerService.setAutoMode(true);
      expect(equalizerService.isAutoMode, true);
    });
  });
}
