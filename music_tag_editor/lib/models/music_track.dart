class MusicTrack {
  final String filePath;
  final String title;
  final String artist;
  final String album;
  final int trackNumber;

  MusicTrack({
    required this.filePath,
    this.title = 'Unknown Title',
    this.artist = 'Unknown Artist',
    this.album = 'Unknown Album',
    this.trackNumber = 0,
  });
}
