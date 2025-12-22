import 'dart:io';
import 'package:path/path.dart' as p;

/// Service for handling Hi-Fi audio formats (FLAC, ALAC, DSD).
class HiFiAudioService {
  static final HiFiAudioService instance = HiFiAudioService._internal();
  HiFiAudioService._internal();

  /// Supported Hi-Fi formats with their metadata.
  static const Map<String, HiFiFormat> supportedFormats = {
    '.flac': HiFiFormat(
      name: 'FLAC',
      description: 'Free Lossless Audio Codec',
      maxBitDepth: 32,
      maxSampleRate: 384000,
      isLossless: true,
    ),
    '.alac': HiFiFormat(
      name: 'ALAC',
      description: 'Apple Lossless Audio Codec',
      maxBitDepth: 32,
      maxSampleRate: 384000,
      isLossless: true,
    ),
    '.m4a': HiFiFormat(
      name: 'AAC/ALAC',
      description: 'MPEG-4 Audio (may be lossless)',
      maxBitDepth: 24,
      maxSampleRate: 96000,
      isLossless: false, // M4A can be AAC or ALAC
    ),
    '.dsf': HiFiFormat(
      name: 'DSD',
      description: 'Direct Stream Digital',
      maxBitDepth: 1,
      maxSampleRate: 11289600, // DSD256
      isLossless: true,
    ),
    '.dff': HiFiFormat(
      name: 'DFF',
      description: 'DSD Interchange File Format',
      maxBitDepth: 1,
      maxSampleRate: 11289600,
      isLossless: true,
    ),
    '.wav': HiFiFormat(
      name: 'WAV',
      description: 'Waveform Audio File',
      maxBitDepth: 32,
      maxSampleRate: 384000,
      isLossless: true,
    ),
    '.aiff': HiFiFormat(
      name: 'AIFF',
      description: 'Audio Interchange File Format',
      maxBitDepth: 32,
      maxSampleRate: 384000,
      isLossless: true,
    ),
  };

  /// Check if a file is a Hi-Fi format.
  bool isHiFiFormat(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return supportedFormats.containsKey(ext);
  }

  /// Get format info for a file.
  HiFiFormat? getFormatInfo(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return supportedFormats[ext];
  }

  /// Analyze audio file quality using FFprobe.
  Future<AudioQualityInfo?> analyzeQuality(String filePath) async {
    try {
      final result = await Process.run('ffprobe', [
        '-v',
        'quiet',
        '-print_format',
        'json',
        '-show_streams',
        '-select_streams',
        'a:0',
        filePath,
      ]);

      if (result.exitCode != 0) { return null; }

      final output = result.stdout as String;
      // Parse basic info from ffprobe output
      final sampleRateMatch =
          RegExp(r'"sample_rate":\s*"(\d+)"').firstMatch(output);
      final bitsMatch =
          RegExp(r'"bits_per_raw_sample":\s*"(\d+)"').firstMatch(output);
      final bitrateMatch = RegExp(r'"bit_rate":\s*"(\d+)"').firstMatch(output);
      final channelsMatch = RegExp(r'"channels":\s*(\d+)').firstMatch(output);

      return AudioQualityInfo(
        sampleRate: sampleRateMatch != null
            ? int.tryParse(sampleRateMatch.group(1)!) ?? 0
            : 0,
        bitDepth:
            bitsMatch != null ? int.tryParse(bitsMatch.group(1)!) ?? 16 : 16,
        bitrate: bitrateMatch != null
            ? int.tryParse(bitrateMatch.group(1)!) ?? 0
            : 0,
        channels: channelsMatch != null
            ? int.tryParse(channelsMatch.group(1)!) ?? 2
            : 2,
        format: getFormatInfo(filePath),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get quality tier label for display.
  String getQualityTier(AudioQualityInfo info) {
    if (info.sampleRate >= 96000 && info.bitDepth >= 24) {
      return 'Hi-Res';
    } else if (info.format?.isLossless == true) {
      return 'Lossless';
    } else if (info.bitrate >= 256000) {
      return 'High Quality';
    } else {
      return 'Standard';
    }
  }
}

/// Metadata for a Hi-Fi audio format.
class HiFiFormat {
  final String name;
  final String description;
  final int maxBitDepth;
  final int maxSampleRate;
  final bool isLossless;

  const HiFiFormat({
    required this.name,
    required this.description,
    required this.maxBitDepth,
    required this.maxSampleRate,
    required this.isLossless,
  });
}

/// Quality information for an audio file.
class AudioQualityInfo {
  final int sampleRate;
  final int bitDepth;
  final int bitrate;
  final int channels;
  final HiFiFormat? format;

  const AudioQualityInfo({
    required this.sampleRate,
    required this.bitDepth,
    required this.bitrate,
    required this.channels,
    this.format,
  });

  String get sampleRateDisplay =>
      '${(sampleRate / 1000).toStringAsFixed(1)} kHz';
  String get bitDepthDisplay => '$bitDepth-bit';
  String get bitrateDisplay => '${(bitrate / 1000).round()} kbps';
  String get channelsDisplay => channels == 2 ? 'Stereo' : '$channels ch';
}
