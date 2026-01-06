/// Unified result from metadata aggregation.
class AggregatedMetadata {
  final String? title;
  final String? artist;
  final String? album;
  final String? genre;
  final int? year;
  final String? thumbnail;
  final List<String> allGenres;
  final double confidence; // 0.0 to 1.0 based on source agreement

  AggregatedMetadata({
    this.title,
    this.artist,
    this.album,
    this.genre,
    this.year,
    this.thumbnail,
    this.allGenres = const [],
    this.confidence = 0.0,
  });
}
