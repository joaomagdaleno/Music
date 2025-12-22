import 'package:just_audio/just_audio.dart';

class EqualizerService {
  static final EqualizerService instance = EqualizerService._internal();
  EqualizerService._internal();

  final AndroidEqualizer _equalizer = AndroidEqualizer();
  bool _isAutoMode = true;

  AndroidEqualizer get equalizer => _equalizer;
  bool get isAutoMode => _isAutoMode;

  void setAutoMode(bool enabled) {
    _isAutoMode = enabled;
  }

  Future<void> applyPresetForGenre(String? genre) async {
    if (!_isAutoMode) return;

    final parameters = await _equalizer.parameters;
    final bands = parameters.bands;

    // Default: Flat
    for (var band in bands) {
      await band.setGain(0.0);
    }

    if (genre == null) return;

    final g = genre.toLowerCase();

    if (g.contains('rock') || g.contains('metal')) {
      // Bass and Treble boost
      if (bands.isNotEmpty) await bands.first.setGain(3.0);
      if (bands.length > 4) await bands.last.setGain(3.0);
    } else if (g.contains('pop') || g.contains('dance')) {
      // V-shaped but milder
      if (bands.isNotEmpty) await bands.first.setGain(2.0);
      if (bands.length > 2) await bands[bands.length ~/ 2].setGain(-1.0);
      if (bands.isNotEmpty) await bands.last.setGain(2.0);
    } else if (g.contains('jazz') || g.contains('classical')) {
      // Mid focus for clarity
      if (bands.length > 2) await bands[bands.length ~/ 2].setGain(2.0);
    } else if (g.contains('bass') || g.contains('hip hop')) {
      // Bass focus
      if (bands.isNotEmpty) await bands.first.setGain(5.0);
      if (bands.length > 1) await bands[1].setGain(3.0);
    }
  }

  Future<void> setCustomBand(int index, double gain) async {
    _isAutoMode = false;
    final parameters = await _equalizer.parameters;
    if (index < parameters.bands.length) {
      await parameters.bands[index].setGain(gain);
    }
  }
}
