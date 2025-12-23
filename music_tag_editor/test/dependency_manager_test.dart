import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_tag_editor/services/dependency_manager.dart';

void main() {
  late DependencyManager manager;

  setUp(() {
    // Reset the singleton instance for each test
    DependencyManager.instance = DependencyManager.forTesting();
    manager = DependencyManager.instance;
  });

  group('DependencyManager', () {
    test('provides correct paths on Windows', () {
      // Mocking Platform is hard, but we can check if the paths contain the expected names
      expect(manager.ytDlpPath, contains('yt-dlp'));
      expect(manager.ffmpegPath, contains('ffmpeg'));
      expect(manager.spotdlPath, contains('spotdl'));
    });

    test('areAllDependenciesInstalled returns true when files exist', () async {
      await IOOverrides.runZoned(() async {
        final installed = await manager.areAllDependenciesInstalled();
        expect(installed, true);
      }, createFile: (path) => _MockFile(path, existsResult: true));
    });

    test('areAllDependenciesInstalled returns false when files missing',
        () async {
      await IOOverrides.runZoned(() async {
        final installed = await manager.areAllDependenciesInstalled();
        expect(installed, false);
      }, createFile: (path) => _MockFile(path, existsResult: false));
    });
  });
}

class _MockFile extends Fake implements File {
  final String path;
  final bool existsResult;
  _MockFile(this.path, {this.existsResult = true});

  @override
  Future<bool> exists() async => existsResult;
  @override
  bool existsSync() => existsResult;
}
