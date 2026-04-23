import 'package:music_tag_editor/src/rust/api/watcher.dart' as rust;
import 'package:music_tag_editor/services/metadata_service.dart';
import 'package:music_tag_editor/services/database_service.dart';

class WatcherService {
  static final WatcherService _instance = WatcherService._internal();
  static WatcherService get instance => _instance;

  WatcherService._internal();

  bool _isWatching = false;

  void startWatching(String folderPath) {
    if (_isWatching) return;
    _isWatching = true;

    // O FRB v2 transforma o StreamSink em um Stream nativo do Dart
    rust.startWatcher(folderPath: folderPath).then((stream) {
      stream.listen((filePath) async {
        print('Arquivo alterado detectado: $filePath');
        
        // Sincronização Automática:
        // 1. Ler novos metadados via Rust
        try {
          final metadata = await MetadataService.instance.readMetadata(filePath);
          
          // 2. Salvar no Banco de Dados Nativo
          await DatabaseService.instance.saveTrack({
            'id': filePath.hashCode.toString(),
            'title': metadata['title'],
            'artist': metadata['artist'],
            'album': metadata['album'],
            'local_path': filePath,
          });
        } catch (e) {
          print('Erro ao sincronizar arquivo: $e');
        }
      });
    });
  }
}
