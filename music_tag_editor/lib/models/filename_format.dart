// Enum to represent the different filename formats.
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
    switch (this) {
      case FilenameFormat.artistTitle:
        return '$artist - $title';
      case FilenameFormat.titleArtist:
        return '$title ($artist)';
      case FilenameFormat.trackArtistTitle:
        final trackStr = trackNumber.toString().padLeft(2, '0');
        return '$trackStr. $artist - $title';
    }
  }
}
