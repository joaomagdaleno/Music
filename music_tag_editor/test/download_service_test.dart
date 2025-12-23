import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';

class MockDependencyManager extends Mock implements DependencyManager {}

class MockProcess extends Mock implements Process {}

void main() {
  group('DownloadService Tests', () {
    late DownloadService downloadService;
    late MockDependencyManager mockDeps;

    setUp(() {
      mockDeps = MockDependencyManager();
      DependencyManager.instance = mockDeps;
      downloadService = DownloadService();

      when(() => mockDeps.ytDlpPath).thenReturn('yt-dlp');
      when(() => mockDeps.ffmpegPath).thenReturn('ffmpeg');
      when(() => mockDeps.spotdlPath).thenReturn('spotdl');
    });

    test('detectPlatform identifies platforms correctly', () {
      expect(
          downloadService.detectPlatform('https://www.youtube.com/watch?v=123'),
          MediaPlatform.youtube);
      expect(
          downloadService
              .detectPlatform('https://music.youtube.com/watch?v=123'),
          MediaPlatform.youtubeMusic);
      expect(
          downloadService.detectPlatform('https://open.spotify.com/track/123'),
          MediaPlatform.spotify);
      expect(downloadService.detectPlatform('https://example.com'),
          MediaPlatform.unknown);
    });

    test('downloadYouTube reports progress and returns path', () async {
      final mockProcess = MockProcess();
      final stdoutController = StreamController<List<int>>();
      final stderrController = StreamController<List<int>>();

      when(() => mockProcess.stdout).thenAnswer((_) => stdoutController.stream);
      when(() => mockProcess.stderr).thenAnswer((_) => stderrController.stream);
      when(() => mockProcess.exitCode).thenAnswer((_) => Future.value(0));

      downloadService.processStarter = (executable, arguments,
              {workingDirectory,
              environment,
              includeParentEnvironment = true,
              runInShell = false,
              mode = ProcessStartMode.normal}) async =>
          mockProcess;

      final progressUpdates = <double>[];
      final format = DownloadFormat(
          formatId: 'best',
          extension: 'mp3',
          quality: '320k',
          isAudioOnly: true);

      final downloadFuture = downloadService.download(
        'https://youtube.com/watch?v=test',
        format,
        '/downloads',
        onProgress: (progress, status) => progressUpdates.add(progress),
      );

      stdoutController.add(
          utf8.encode('[download] Destination: /downloads/Test Song.mp3\n'));
      stdoutController.add(utf8
          .encode('[download]  10.0% of 10.0MiB at  1.00MiB/s ETA 00:09\n'));
      stdoutController.add(utf8
          .encode('[download]  100.0% of 10.0MiB at  1.00MiB/s ETA 00:00\n'));
      await stdoutController.close();
      await stderrController.close();

      final resultPath = await downloadFuture;

      expect(resultPath, '/downloads/Test Song.mp3');
      expect(progressUpdates, contains(0.1));
      expect(progressUpdates, contains(1.0));
    });

    test('getMediaInfo parses yt-dlp json correctly', () async {
      final jsonOutput = jsonEncode({
        'title': 'Downloaded Song',
        'uploader': 'Artist Name',
        'thumbnail': 'http://thumb',
        'duration': 300,
        'formats': [
          {
            'format_id': '140',
            'ext': 'm4a',
            'acodec': 'mp4a',
            'vcodec': 'none',
            'abr': 128
          }
        ]
      });
      final mockResult = ProcessResult(0, 0, jsonOutput, '');

      downloadService.processRunner = (executable, arguments,
              {environment,
              includeParentEnvironment = true,
              runInShell = false,
              stdoutEncoding,
              stderrEncoding}) async =>
          mockResult;

      final info = await downloadService
          .getMediaInfo('https://youtube.com/watch?v=test');

      expect(info.title, 'Downloaded Song');
      expect(info.artist, 'Artist Name');
      expect(info.formats.any((f) => f.formatId == '140'), true);
    });

    test('_embedCustomThumbnail logic flow', () async {
      await IOOverrides.runZoned(() async {
        final mockProcess = MockProcess();
        final stdoutController = StreamController<List<int>>();
        final stderrController = StreamController<List<int>>();

        when(() => mockProcess.stdout)
            .thenAnswer((_) => stdoutController.stream);
        when(() => mockProcess.stderr)
            .thenAnswer((_) => stderrController.stream);
        when(() => mockProcess.exitCode).thenAnswer((_) => Future.value(0));

        downloadService.processStarter = (executable, arguments,
                {workingDirectory,
                environment,
                includeParentEnvironment = true,
                runInShell = false,
                mode = ProcessStartMode.normal}) async =>
            mockProcess;

        int ffmpegCalls = 0;
        downloadService.processRunner = (executable, arguments,
            {environment,
            includeParentEnvironment = true,
            runInShell = false,
            stdoutEncoding,
            stderrEncoding}) async {
          ffmpegCalls++;
          return ProcessResult(0, 0, '', '');
        };

        downloadService.fileDownloader = (url, path) async {};

        final format = DownloadFormat(
            formatId: 'best',
            extension: 'mp3',
            quality: '320k',
            isAudioOnly: true);

        stdoutController.add(utf8.encode('[download] Destination: song.mp3\n'));

        final downloadFuture = downloadService.download(
          'https://youtube.com/watch?v=test',
          format,
          '/dir',
          overrideThumbnailUrl: 'http://custom-thumb',
        );

        await stdoutController.close();
        await stderrController.close();

        final result = await downloadFuture;

        expect(result, isNotNull);
        expect(ffmpegCalls, 1);
      }, createFile: (path) => _MockFile(path));
    });
  });
}

class _MockFile extends Fake implements File {
  @override
  final String path;
  _MockFile(this.path);

  @override
  Future<bool> exists() async => true;
  @override
  bool existsSync() => true;
  @override
  Future<File> delete({bool recursive = false}) async => this;
  @override
  Future<File> rename(String newPath) async => _MockFile(newPath);
}
