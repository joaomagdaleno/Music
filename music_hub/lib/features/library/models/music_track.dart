class MusicTrack {
  final String filePath;
  final String title;
  final String artist;
  final String album;

  /// Track number in "x/y" format (e.g., "5/10") to preserve total tracks info.
  final String trackNumber;

  MusicTrack({
    required this.filePath,
    this.title = 'Unknown Title',
    this.artist = 'Unknown Artist',
    this.album = 'Unknown Album',
    this.trackNumber = '',
  });
}
