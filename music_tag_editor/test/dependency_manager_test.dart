@Tags(['unit'])
library;

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:music_tag_editor/services/dependency_manager.dart';
import 'package:archive/archive.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late DependencyManager manager;
  late MockHttpClient mockClient;

  setUp(() {
    mockClient = MockHttpClient();
    manager = DependencyManager.forTesting(client: mockClient);
  });

  group('DependencyManager', () {
    test('provides correct paths on Windows', () {
      expect(manager.ytDlpPath, contains('yt-dlp'));
      expect(manager.ffmpegPath, contains('ffmpeg'));
      expect(manager.spotdlPath, contains('spotdl'));
    });

    test('downloadFile successful', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response('content', 200),
      );

      final tempDir = Directory.systemTemp.createTempSync();
      final filePath = '${tempDir.path}/test.txt';

      try {
        await manager.downloadFile('http://example.com/test.txt', filePath);
        final file = File(filePath);
        expect(file.existsSync(), true);
        expect(file.readAsStringSync(), 'content');
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });

    test('downloadFile failure throws HttpException', () async {
      when(() => mockClient.get(any())).thenAnswer(
        (_) async => http.Response('Not Found', 404),
      );

      expect(
        () => manager.downloadFile('http://example.com/missing', 'path'),
        throwsA(isA<HttpException>()),
      );
    });

    test('areAllDependenciesInstalled returns true when files exist', () async {
      await IOOverrides.runZoned(() async {
        final installed = await manager.areAllDependenciesInstalled();
        expect(installed, true);
      }, createFile: (path) => _MockFile(path, existsResult: true));
    });

    test('ensureDependencies executes downloads if missing', () async {
      manager =
          DependencyManager.forTesting(client: mockClient, initialized: false);

      final ytDlpJson = jsonEncode({
        'assets': [
          {'name': 'yt-dlp.exe', 'browser_download_url': 'http://yt-dlp-url'},
          {
            'name': 'yt-dlp_linux',
            'browser_download_url': 'http://yt-dlp-url-linux'
          },
          {
            'name': 'yt-dlp_macos',
            'browser_download_url': 'http://yt-dlp-url-macos'
          },
        ]
      });
      final spotDtlJson = jsonEncode({
        'assets': [
          {
            'name': 'spotdl-win32-x64.exe',
            'browser_download_url': 'http://spotdl-url'
          },
          {
            'name': 'spotdl-linux-x64',
            'browser_download_url': 'http://spotdl-url-linux'
          },
          {
            'name': 'spotdl-darwin-x64',
            'browser_download_url': 'http://spotdl-url-macos'
          }
        ]
      });

      final ffmpegZipBytes = ZipEncoder().encode(Archive()
        ..addFile(ArchiveFile('ffmpeg.exe', 11, utf8.encode('exe_content'))))!;

      when(() => mockClient.get(
              any(that: predicate((Uri u) => u.toString().contains('yt-dlp')))))
          .thenAnswer((_) async => http.Response(ytDlpJson, 200));
      when(() => mockClient.get(any(
              that: predicate(
                  (Uri u) => u.toString().contains('spotify-downloader')))))
          .thenAnswer((_) async => http.Response(spotDtlJson, 200));
      when(() => mockClient.get(any(
              that: predicate((Uri u) => u.toString().contains('ffmpeg.zip')))))
          .thenAnswer((_) async => http.Response.bytes(ffmpegZipBytes, 200));
      when(() => mockClient.get(any(
              that: predicate((Uri u) =>
                  u.toString().contains('fpcalc') ||
                  u.toString().contains('url')))))
          .thenAnswer((_) async => http.Response('binary_content', 200));

      await IOOverrides.runZoned(() async {
        await manager.ensureDependencies(onProgress: (status, progress) {
          // ignore: avoid_print
          print('$status: $progress');
        });
      },
          createFile: (path) =>
              _MockFile(path, existsResult: false, zipContent: ffmpegZipBytes),
          createDirectory: (path) => _MockDirectory(path));

      verify(() => mockClient.get(
              any(that: predicate((Uri u) => u.toString().contains('yt-dlp')))))
          .called(greaterThanOrEqualTo(1));
    });
  });
}

class _MockFile extends Fake implements File {
  @override
  final String path;
  final bool existsResult;
  final List<int>? zipContent;
  _MockFile(this.path, {this.existsResult = true, this.zipContent});

  @override
  Future<bool> exists() async => existsResult;
  @override
  bool existsSync() => existsResult;
  @override
  Future<File> writeAsBytes(List<int> bytes,
          {FileMode mode = FileMode.write, bool flush = false}) async =>
      this;
  @override
  Future<Uint8List> readAsBytes() async {
    if (path.endsWith('.zip') && zipContent != null) {
      return Uint8List.fromList(zipContent!);
    }
    return Uint8List.fromList(utf8.encode('dummy_content'));
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async => this;
}

class _MockDirectory extends Fake implements Directory {
  @override
  final String path;
  _MockDirectory(this.path);
  @override
  Future<bool> exists() async => true;
  @override
  Future<Directory> create({bool recursive = false}) async => this;
}
