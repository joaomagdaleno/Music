import 'dart:typed_data';

class MusicTrack {
  final String filePath;
  final String title;
  final String artist;
  final String album;
  final int trackNumber;
  final Uint8List? albumArt; // Kept for future use, but not populated by MetadataService yet
  final String? lyrics;

  MusicTrack({
    required this.filePath,
    this.title = 'Unknown Title',
    this.artist = 'Unknown Artist',
    this.album = 'Unknown Album',
    this.trackNumber = 0,
    this.albumArt,
    this.lyrics,
  });
}
