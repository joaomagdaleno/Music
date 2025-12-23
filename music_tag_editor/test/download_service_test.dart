import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/dependency_manager.dart';

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
          mode = ProcessStartMode.normal}) async {
        return mockProcess;
      };

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

      // Simulate yt-dlp output
      stdoutController.add(
          utf8.encode('[download] Destination: /downloads/Test Song.mp3\n'));
      stdoutController.add(utf8
          .encode('[download]  10.0% of 10.00MiB at  1.00MiB/s ETA 00:09\n'));
      stdoutController.add(utf8
          .encode('[download]  50.0% of 10.00MiB at  1.00MiB/s ETA 00:05\n'));
      stdoutController.add(utf8
          .encode('[download] 100.0% of 10.00MiB at  1.00MiB/s ETA 00:00\n'));
      await stdoutController.close();
      await stderrController.close();

      final resultPath = await downloadFuture;

      expect(resultPath, '/downloads/Test Song.mp3');
      expect(progressUpdates, contains(0.1));
      expect(progressUpdates, contains(0.5));
      expect(progressUpdates, contains(1.0));
    });

    test('downloadSpotify returns outputDir on success', () async {
      final mockResult = ProcessResult(0, 0, 'Done', '');

      downloadService.processRunner = (executable, arguments,
          {environment,
          includeParentEnvironment = true,
          runInShell = false,
          stdoutEncoding,
          stderrEncoding}) async {
        return mockResult;
      };

      final format = DownloadFormat(
          formatId: 'mp3',
          extension: 'mp3',
          quality: '320k',
          isAudioOnly: true);
      final resultPath = await downloadService.download(
        'https://open.spotify.com/track/test',
        format,
        '/downloads',
      );

      expect(resultPath, '/downloads');
    });
  });
}

