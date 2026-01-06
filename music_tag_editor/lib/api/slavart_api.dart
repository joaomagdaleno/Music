import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:music_tag_editor/utils/rate_limiter.dart';
import 'package:music_tag_editor/utils/file_utils.dart';

/// SlavArt Divolt API for FLAC downloads from Tidal/Qobuz/Deezer.
class SlavArtApi {
  static const String _baseUrl = 'https://slavart.gamesdrive.net';
  static const String _downloadBase = 'https://slavart-api.gamesdrive.net';

  final http.Client _client;
  final bool _isTestClient;
  final RateLimiter _rateLimiter;

  SlavArtApi({http.Client? client})
      : _client = client ?? DependencyManager.instance.client,
        _isTestClient = client != null,
        _rateLimiter = RateLimiter(maxRequests: 30, interval: const Duration(minutes: 1));

  /// Search for a track across all Hi-Fi platforms.
  Future<List<SlavArtResult>> search(String query) async {
    try {
      await _rateLimiter.wait();
      // SlavArt uses a simple search endpoint
      final uri = Uri.parse('$_baseUrl/api/search').replace(
        queryParameters: {'q': query},
      );

      final response = await _client.get(uri).timeout(
            const Duration(seconds: 15),
          );

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body);
      final results = <SlavArtResult>[];

      // Parse results from different sources with defensive structure handling
      for (final source in ['qobuz', 'tidal', 'deezer']) {
        final sourceData = data[source];
        List<dynamic> items;
        
        // Handle both direct list and nested { "results": [...] } structures
        if (sourceData is List) {
          items = sourceData;
        } else if (sourceData is Map && sourceData['results'] is List) {
          items = sourceData['results'] as List;
        } else {
          items = [];
        }
        
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            results.add(SlavArtResult.fromJson(item, source));
          }
        }
      }

      return results;
    } catch (e) {
      debugPrint('❌ SlavArt Search Error: $e');
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

      if (response.statusCode != 200) {
        return null;
      }

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
    IOSink? sink;
    try {
      // SSRF Protection: Strictly validate URL scheme
      final uri = Uri.parse(downloadUrl);
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        debugPrint('❌ SlavArt: Invalid or dangerous URL scheme: ${uri.scheme}');
        return null;
      }

      final request = http.Request('GET', uri);
      final streamedResponse = await _client.send(request);

      if (streamedResponse.statusCode != 200) {
        return null;
      }

      // Get filename from headers or generate one
      final contentDisposition =
          streamedResponse.headers['content-disposition'];
      String filename =
          'download_${DateTime.now().millisecondsSinceEpoch}.flac';

      if (contentDisposition != null) {
        final match =
            RegExp(r'filename="?([^"]+)"?').firstMatch(contentDisposition);
        if (match != null) {
          final rawName = match.group(1)!;
          // Use shared utility for sanitization
          var cleanName = sanitizeFilename(rawName);
          
          // Enforce extension
          if (!cleanName.toLowerCase().endsWith('.flac') && !cleanName.toLowerCase().endsWith('.mp3')) {
            cleanName += '.flac';
          }
           
          filename = cleanName;
        }
      }

      final outputFile = File(p.join(outputDir, filename));
      sink = outputFile.openWrite();

      final totalBytes = streamedResponse.contentLength ?? 0;

      // Non-blocking: Use addStream to avoid UI freezes during large downloads.
      // Progress reporting is sacrificed for performance; use onDone callback instead.
      if (onProgress != null && totalBytes > 0) {
        // If progress is needed, we have to use the manual loop, but we'll
        // do it in a way that yields to the event loop more often.
        int receivedBytes = 0;
        await for (final chunk in streamedResponse.stream) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          onProgress(receivedBytes / totalBytes);
          // Yield to event loop every 1MB to prevent jank
          if (receivedBytes % (1024 * 1024) < chunk.length) {
            await Future<void>.delayed(Duration.zero);
          }
        }
      } else {
        // Optimal: No progress callback, use efficient addStream
        await sink.addStream(streamedResponse.stream);
      }

      await sink.flush();
      return outputFile;
    } catch (e) {
      debugPrint('❌ SlavArt Download Error: $e');
      return null;
    } finally {
      await sink?.close();
    }
  }

  void dispose() {
    // IMPORTANT: Never close the shared client from DependencyManager.
    // Only close if we own a test client.
    if (_isTestClient) {
      _client.close();
    }
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

  factory SlavArtResult.fromJson(Map<String, dynamic> json, String source) =>
      SlavArtResult(
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
        if (quality == 'HI_RES') {
          return 'MQA 24-bit';
        }
        if (quality == 'LOSSLESS') {
          return 'FLAC 16-bit';
        }
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
      if (first is Map) {
        return first['name']?.toString() ?? 'Unknown';
      }
      if (first is String) {
        return first;
      }
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
