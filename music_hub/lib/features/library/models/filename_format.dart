// Enum to represent the different filename formats.
import 'package:music_hub/utils/file_utils.dart';

enum FilenameFormat {
  artistTitle,
  titleArtist,
  trackArtistTitle,
}

extension FilenameFormatExtension on FilenameFormat {
  String generateFilename({
    required String artist,
    required String title,
    required int trackNumber,
  }) {
    final safeArtist = _sanitize(artist);
    final safeTitle = _sanitize(title);

    switch (this) {
      case FilenameFormat.artistTitle:
        return '$safeArtist - $safeTitle';
      case FilenameFormat.titleArtist:
        return '$safeTitle ($safeArtist)';
      case FilenameFormat.trackArtistTitle:
        final trackStr = trackNumber.toString().padLeft(2, '0');
        return '$trackStr. $safeArtist - $safeTitle';
    }
  }

  String _sanitize(String input) => sanitizeFilename(input);
}
