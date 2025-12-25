@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_tag_editor/services/equalizer_service.dart';

class MockAndroidEqualizer extends Mock implements AndroidEqualizer {}

class MockEqualizerParameters extends Mock
    implements AndroidEqualizerParameters {}

class MockAndroidEqualizerBand extends Mock implements AndroidEqualizerBand {}

void main() {
  late EqualizerService service;
  late MockAndroidEqualizer mockEqualizer;
  late MockEqualizerParameters mockParameters;

  setUp(() {
    mockEqualizer = MockAndroidEqualizer();
    mockParameters = MockEqualizerParameters();
    service = EqualizerService.test(equalizer: mockEqualizer);

    when(() => mockEqualizer.parameters)
        .thenAnswer((_) async => mockParameters);
  });

  group('EqualizerService', () {
    test('applyPresetForGenre sets bands correctly for Rock', () async {
      final band1 = MockAndroidEqualizerBand();
      final band2 = MockAndroidEqualizerBand();
      final bands = [band1, band2];

      when(() => mockParameters.bands).thenReturn(bands);
      when(() => band1.setGain(any())).thenAnswer((_) async {});
      when(() => band2.setGain(any())).thenAnswer((_) async {});

      await service.applyPresetForGenre('Rock');

      verify(() => band1.setGain(0.0)).called(1); // Reset
      verify(() => band1.setGain(3.0)).called(1); // Boost
    });

    test('calculateNormalizedVolume calculates gain adjustment', () {
      service.setNormalization(true);
      service.setTargetLoudness(-14.0);

      // Track matches target
      expect(service.calculateNormalizedVolume(-14.0), closeTo(1.0, 0.01));

      // Track too quiet (-20dB), should boost (+6dB -> ~2.0x)
      expect(service.calculateNormalizedVolume(-20.0), closeTo(1.99, 0.01));

      // Track too loud (-8dB), should attenuate (-6dB -> ~0.5x)
      expect(service.calculateNormalizedVolume(-8.0), closeTo(0.5, 0.01));
    });
  });
}
