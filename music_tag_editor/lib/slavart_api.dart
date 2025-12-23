import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// SlavArt Divolt API for FLAC downloads from Tidal/Qobuz/Deezer.
class SlavArtApi {
  static const String _baseUrl = 'https://slavart.gamesdrive.net';
  static const String _downloadBase = 'https://slavart-api.gamesdrive.net';

  final http.Client _client = http.Client();

  /// Search for a track across all Hi-Fi platforms.
  Future<List<SlavArtResult>> search(String query) async {
    try {
      // SlavArt uses a simple search endpoint
      final uri = Uri.parse('$_baseUrl/api/search').replace(
        queryParameters: {'q': query},
      );

      final response = await _client.get(uri).timeout(
            const Duration(seconds: 15),
          );

      if (response.statusCode != 200) { return []; }

      final data = jsonDecode(response.body);
      final results = <SlavArtResult>[];

      // Parse results from different sources
      for (final source in ['qobuz', 'tidal', 'deezer']) {
        final items = data[source] as List? ?? [];
        for (final item in items) {
          results.add(SlavArtResult.fromJson(item, source));
        }
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  /// Get download URL for a track.
  Future<String?> getDownloadUrl(String trackUrl) async {
    try {
      final uri = Uri.parse('$_downloadBase/api/download').replace(
        queryParameters: {'url': trackUrl},
      );

      final response = await _client.get(uri).timeout(
            const Duration(seconds: 30),
          );

      if (response.statusCode != 200) { return null; }

      final data = jsonDecode(response.body);
      return data['download_url'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Download FLAC file to specified directory.
  Future<File?> downloadFlac(
    String downloadUrl,
    String outputDir, {
    void Function(double progress)? onProgress,
  }) async {
    try {
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final streamedResponse = await _client.send(request);

      if (streamedResponse.statusCode != 200) { return null; }

      // Get filename from headers or generate one
      final contentDisposition =
          streamedResponse.headers['content-disposition'];
      String filename =
          'download_${DateTime.now().millisecondsSinceEpoch}.flac';

      if (contentDisposition != null) {
        final match =
            RegExp(r'filename="?([^"]+)"?').firstMatch(contentDisposition);
        if (match != null) {
          filename = match.group(1)!;
        }
      }

      final outputFile = File(p.join(outputDir, filename));
      final sink = outputFile.openWrite();

      final totalBytes = streamedResponse.contentLength ?? 0;
      int receivedBytes = 0;

      await for (final chunk in streamedResponse.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0 && onProgress != null) {
          onProgress(receivedBytes / totalBytes);
        }
      }

      await sink.close();
      return outputFile;
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Result from SlavArt search.
class SlavArtResult {
  final String id;
  final String title;
  final String artist;
  final String? album;
  final String? thumbnail;
  final int? duration;
  final String source; // 'qobuz', 'tidal', 'deezer'
  final String url;
  final String? quality; // e.g. '24-bit/96kHz', 'FLAC'

  SlavArtResult({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.thumbnail,
    this.duration,
    required this.source,
    required this.url,
    this.quality,
  });

  factory SlavArtResult.fromJson(Map<String, dynamic> json, String source) {
    return SlavArtResult(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? 'Unknown',
      artist: _extractArtist(json),
      album: json['album']?['title'] ?? json['album']?['name'],
      thumbnail: json['cover'] ?? json['album']?['cover'] ?? json['image'],
      duration: json['duration'] as int?,
      source: source,
      url: json['url'] ?? json['link'] ?? '',
      quality: _parseQuality(json, source),
    );
  }

  static String? _parseQuality(Map<String, dynamic> json, String source) {
    switch (source) {
      case 'qobuz':
        final bits = json['maximum_bit_depth'];
        final rate = json['maximum_sampling_rate'];
        if (bits != null && rate != null) {
          return '$bits-bit/${rate}kHz';
        }
        return 'FLAC';
      case 'tidal':
        final quality = json['audioQuality'];
        if (quality == 'HI_RES') { return 'MQA 24-bit'; }
        if (quality == 'LOSSLESS') { return 'FLAC 16-bit'; }
        return quality;
      case 'deezer':
        return 'FLAC 16-bit';
      default:
        return null;
    }
  }

  static String _extractArtist(Map<String, dynamic> json) {
    if (json['artist'] is Map) {
      return (json['artist'] as Map)['name']?.toString() ?? 'Unknown';
    }
    if (json['artists'] is List && (json['artists'] as List).isNotEmpty) {
      final first = (json['artists'] as List).first;
      if (first is Map) { return first['name']?.toString() ?? 'Unknown'; }
      if (first is String) { return first; }
    }
    if (json['performer'] is Map) {
      return (json['performer'] as Map)['name']?.toString() ?? 'Unknown';
    }
    return json['artist']?.toString() ?? 'Unknown';
  }

  /// Get quality badge color based on source.
  String get qualityBadge {
    switch (source) {
      case 'qobuz':
        return '🟣 Qobuz';
      case 'tidal':
        return '🔵 Tidal';
      case 'deezer':
        return '🟢 Deezer';
      default:
        return source;
    }
  }
}
