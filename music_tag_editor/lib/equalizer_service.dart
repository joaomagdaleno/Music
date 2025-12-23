import 'dart:math' as math;
import 'package:just_audio/just_audio.dart';
import 'package:meta/meta.dart';

class EqualizerService {
  static EqualizerService _instance = EqualizerService._internal();
  static EqualizerService get instance => _instance;

  @visibleForTesting
  static set instance(EqualizerService mock) => _instance = mock;

  EqualizerService._internal();

  final AndroidEqualizer _equalizer = AndroidEqualizer();
  bool _isAutoMode = true;
  bool _normalizationEnabled = false;
  double _targetLoudness = -14.0; // LUFS (Spotify standard)

  AndroidEqualizer get equalizer => _equalizer;
  bool get isAutoMode => _isAutoMode;
  bool get normalizationEnabled => _normalizationEnabled;
  double get targetLoudness => _targetLoudness;

  void setAutoMode(bool enabled) {
    _isAutoMode = enabled;
  }

  Future<void> applyPresetForGenre(String? genre) async {
    if (!_isAutoMode) {
      return;
    }

    final parameters = await _equalizer.parameters;
    final bands = parameters.bands;

    // Default: Flat
    for (var band in bands) {
      await band.setGain(0.0);
    }

    if (genre == null) {
      return;
    }

    final g = genre.toLowerCase();

    if (g.contains('rock') || g.contains('metal')) {
      // Bass and Treble boost
      if (bands.isNotEmpty) {
        await bands.first.setGain(3.0);
      }
      if (bands.length > 4) {
        await bands.last.setGain(3.0);
      }
    } else if (g.contains('pop') || g.contains('dance')) {
      // V-shaped but milder
      if (bands.isNotEmpty) {
        await bands.first.setGain(2.0);
      }
      if (bands.length > 2) {
        await bands[bands.length ~/ 2].setGain(-1.0);
      }
      if (bands.isNotEmpty) {
        await bands.last.setGain(2.0);
      }
    } else if (g.contains('jazz') || g.contains('classical')) {
      // Mid focus for clarity
      if (bands.length > 2) {
        await bands[bands.length ~/ 2].setGain(2.0);
      }
    } else if (g.contains('bass') || g.contains('hip hop')) {
      // Bass focus
      if (bands.isNotEmpty) {
        await bands.first.setGain(5.0);
      }
      if (bands.length > 1) {
        await bands[1].setGain(3.0);
      }
    }
  }

  Future<void> setCustomBand(int index, double gain) async {
    _isAutoMode = false;
    final parameters = await _equalizer.parameters;
    if (index < parameters.bands.length) {
      await parameters.bands[index].setGain(gain);
    }
  }

  /// Enable/disable volume normalization.
  void setNormalization(bool enabled) {
    _normalizationEnabled = enabled;
  }

  /// Set target loudness for normalization.
  void setTargetLoudness(double lufs) {
    _targetLoudness = lufs.clamp(-24.0, 0.0);
  }

  /// Calculate volume adjustment for a track.
  /// In a real implementation, you'd analyze the file's LUFS with FFmpeg.
  /// For now, this returns 1.0 (no change) as a placeholder.
  double calculateNormalizedVolume(double? trackLufs) {
    if (!_normalizationEnabled || trackLufs == null) {
      return 1.0;
    }

    final adjustment = _targetLoudness - trackLufs;
    // Convert dB to linear scale
    return _dbToLinear(adjustment).clamp(0.1, 2.0);
  }

  double _dbToLinear(double db) {
    return math.pow(10.0, db / 20.0).toDouble();
  }
}
