import 'dart:async';
import 'dart:io';

class DirectoryWatcher {
  final Directory directory;
  final Function onFilesChanged;

  DirectoryWatcher({required this.directory, required this.onFilesChanged});

  StreamSubscription<FileSystemEvent>? _subscription;

  void start() {
    _subscription = directory.watch(recursive: true).listen((event) {
      if (event.type == FileSystemEvent.create) {
        onFilesChanged();
      }
    });
  }

  void stop() {
    _subscription?.cancel();
  }
}
