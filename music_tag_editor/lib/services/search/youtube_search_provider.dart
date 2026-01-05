import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:music_tag_editor/models/download_models.dart';
import 'package:music_tag_editor/models/search_models.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:music_tag_editor/services/search/search_provider.dart';
import 'package:music_tag_editor/services/startup_logger.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

/// Base for YouTube-based search providers.
abstract class BaseYouTubeSearchProvider implements SearchProvider {
  final DependencyManager _deps = DependencyManager.instance;
  final yt.YoutubeExplode ytExplode = yt.YoutubeExplode();

  @override
  bool supports(String url) =>
      url.contains('youtube.com') || url.contains('youtu.be');

  @protected
  SearchResult parseYouTubeVideo(yt.Video video, MediaPlatform platform) {
    String title = video.title;
    String artist = video.author.replaceAll(' - Topic', '').trim();

    title = SearchResult.cleanMetadata(title);

    if (video.title.contains(' - ')) {
      final parts = video.title.split(' - ');
      if (parts.length >= 2) {
        final potentialArtist = SearchResult.cleanMetadata(parts[0]);
        final potentialTitle =
            SearchResult.cleanMetadata(parts.sublist(1).join(' - '));

        final genericAuthors = [
          '7clouds',
          'proximity',
          'trap nation',
          'official music',
          'official',
          'vevo',
          'lyrics',
          'audio',
          'music',
          'videos',
          'records',
          'entertainment'
        ];
        final bool isGeneric =
            genericAuthors.any((g) => artist.toLowerCase().contains(g)) ||
                video.author.toLowerCase().contains('topic');
        final bool authorMatchesTitle = SearchResult.toMatchKey(artist)
                .contains(SearchResult.toMatchKey(potentialArtist)) ||
            SearchResult.toMatchKey(potentialArtist)
                .contains(SearchResult.toMatchKey(artist));

        if (isGeneric || !authorMatchesTitle) {
          artist = potentialArtist;
          title = potentialTitle;
        }
      }
    }

    title = title
        .replaceAll(RegExp(r'ft\..*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'feat\..*$', caseSensitive: false), '')
        .trim();

    return SearchResult(
      id: video.id.value,
      title: title,
      artist: artist,
      thumbnail: video.thumbnails.highResUrl,
      duration: video.duration?.inSeconds,
      url: video.url,
      platform: platform,
    );
  }

  @protected
  Future<List<SearchResult>> searchWithYtDlp(
      String query, MediaPlatform platform) async {
    try {
      final results = <SearchResult>[];
      final args = [
        '--dump-json',
        '--flat-playlist',
        '--no-playlist',
        'ytsearch10:$query',
      ];

      final result = await Process.run(
        _deps.ytDlpPath,
        args,
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (result.exitCode == 0) {
        final lines = (result.stdout as String).split('\n');
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          try {
            final json = jsonDecode(line);
            results.add(SearchResult(
              id: json['id'] as String? ?? '',
              title: SearchResult.cleanMetadata(
                  json['title'] as String? ?? 'Unknown'),
              artist: (json['uploader'] as String? ??
                      json['channel'] as String? ??
                      'Unknown')
                  .replaceAll(' - Topic', '')
                  .trim(),
              thumbnail: json['thumbnail'] as String?,
              duration: (json['duration'] as num?)?.toInt(),
              url: 'https://www.youtube.com/watch?v=${json['id']}',
              platform: platform,
            ));
          } catch (_) {}
        }
      }
      return results;
    } catch (e) {
      StartupLogger.log(
          '[YouTubeSearchProvider] yt-dlp search fallback failed: $e');
      return [];
    }
  }

  @override
  Future<List<DownloadFormat>> getFormats(String url) async {
    try {
      final result = await Process.run(
        _deps.ytDlpPath,
        ['--dump-json', '--no-download', url],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (result.exitCode != 0) {
        return _defaultFormats();
      }

      final json = jsonDecode(result.stdout as String);
      final formats = <DownloadFormat>[];

      formats.add(DownloadFormat(
          formatId: 'bestaudio/best',
          quality: 'Best Audio (MP3)',
          extension: 'mp3',
          isAudioOnly: true));
      formats.add(DownloadFormat(
          formatId: 'bestaudio[ext=m4a]/bestaudio',
          quality: 'Best Audio (M4A)',
          extension: 'm4a',
          isAudioOnly: true));

      final formatsList = json['formats'] as List? ?? [];
      for (final f in formatsList) {
        final formatId = f['format_id'] as String? ?? '';
        final ext = f['ext'] as String? ?? '';
        final vcodec = f['vcodec'] as String? ?? 'none';
        final acodec = f['acodec'] as String? ?? 'none';
        final abr = f['abr'] as num?;

        final isAudioOnly = vcodec == 'none' && acodec != 'none';

        if (isAudioOnly && abr != null) {
          formats.add(DownloadFormat(
            formatId: formatId,
            quality: '${abr.toInt()}kbps',
            extension: ext,
            isAudioOnly: true,
          ));
        }
      }

      return formats;
    } catch (e) {
      return _defaultFormats();
    }
  }

  List<DownloadFormat> _defaultFormats() => [
        DownloadFormat(
            formatId: 'bestaudio/best',
            quality: 'Best Audio (MP3)',
            extension: 'mp3',
            isAudioOnly: true),
        DownloadFormat(
            formatId: 'bestaudio[ext=m4a]/bestaudio',
            quality: 'Best Audio (M4A)',
            extension: 'm4a',
            isAudioOnly: true),
      ];

  @override
  Future<String?> getStreamUrl(String url) async {
    try {
      final videoId = yt.VideoId.parseVideoId(url);
      if (videoId != null) {
        final manifest =
            await ytExplode.videos.streamsClient.getManifest(videoId);
        final audioStream = manifest.audioOnly.withHighestBitrate();
        return audioStream.url.toString();
      }
    } catch (e) {
      StartupLogger.log(
          '[YouTubeSearchProvider] Native extraction failed, fallback to yt-dlp: $e');
    }

    // Fallback to yt-dlp
    try {
      final args = ['--get-url', '-f', 'bestaudio', url];
      final result = await Process.run(_deps.ytDlpPath, args);
      if (result.exitCode == 0) {
        return (result.stdout as String).trim();
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<SearchResult>> importPlaylist(String url) async {
    try {
      final result = await Process.run(
        _deps.ytDlpPath,
        [
          '--dump-json',
          '--flat-playlist',
          '--no-download',
          url,
        ],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (result.exitCode != 0) {
        return [];
      }

      final results = <SearchResult>[];
      final lines = (result.stdout as String).split('\n');

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final json = jsonDecode(line);
          results.add(SearchResult(
            id: json['id'] as String? ?? '',
            title: json['title'] as String? ?? 'Unknown',
            artist: json['uploader'] as String? ??
                json['channel'] as String? ??
                'Unknown',
            thumbnail: json['thumbnail'] as String?,
            duration: (json['duration'] as num?)?.toInt(),
            url: 'https://www.youtube.com/watch?v=${json['id']}',
            platform: MediaPlatform.youtube,
          ));
        } catch (_) {}
      }
      return results;
    } catch (e) {
      return [];
    }
  }
}

class YouTubeSearchProvider extends BaseYouTubeSearchProvider {
  @override
  MediaPlatform get platform => MediaPlatform.youtube;

  @override
  Future<List<SearchResult>> search(String query) async {
    try {
      final results = <SearchResult>[];
      final seenIds = <String>{};
      final seenMeta = <String>{};
      final searchList = await ytExplode.search.search(query);

      for (final video in searchList) {
        if (seenIds.contains(video.id.value)) continue;

        final res = parseYouTubeVideo(video, platform);
        final metaKey =
            '${SearchResult.toMatchKey(res.artist)}:${SearchResult.toMatchKey(res.title)}';

        if (seenMeta.contains(metaKey)) continue;

        results.add(res);
        seenIds.add(video.id.value);
        seenMeta.add(metaKey);
      }
      return results;
    } catch (e, stack) {
      StartupLogger.logError('YouTube Search Provider Error', e, stack);
      return searchWithYtDlp(query, platform);
    }
  }
}

class YouTubeMusicSearchProvider extends BaseYouTubeSearchProvider {
  @override
  MediaPlatform get platform => MediaPlatform.youtubeMusic;

  @override
  Future<List<SearchResult>> search(String query) async {
    try {
      final results = <SearchResult>[];
      final seenIds = <String>{};
      final seenMeta = <String>{};
      final searchList = await ytExplode.search.search('$query topic');

      for (final video in searchList) {
        if (seenIds.contains(video.id.value)) continue;

        final res = parseYouTubeVideo(video, platform);
        final metaKey =
            '${SearchResult.toMatchKey(res.artist)}:${SearchResult.toMatchKey(res.title)}';

        if (seenMeta.contains(metaKey)) continue;

        results.add(res);
        seenIds.add(video.id.value);
        seenMeta.add(metaKey);
      }

      results.sort((a, b) {
        final aTopic = a.artist.toLowerCase().contains('topic') ||
            a.title.toLowerCase().contains('official audio');
        final bTopic = b.artist.toLowerCase().contains('topic') ||
            b.title.toLowerCase().contains('official audio');
        if (aTopic && !bTopic) return -1;
        if (!aTopic && bTopic) return 1;
        return 0;
      });

      return results;
    } catch (e, stack) {
      StartupLogger.logError('YouTube Music Search Provider Error', e, stack);
      return searchWithYtDlp('$query topic', platform);
    }
  }

  @override
  Future<List<SearchResult>> importPlaylist(String url) async =>
      (await super.importPlaylist(url))
          .map((r) => SearchResult(
                id: r.id,
                title: r.title,
                artist: r.artist,
                album: r.album,
                thumbnail: r.thumbnail,
                duration: r.duration,
                url: r.url,
                platform: MediaPlatform.youtubeMusic,
              ))
          .toList();
}
