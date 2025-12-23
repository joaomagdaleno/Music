import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'backup_service.dart';

class BackupView extends StatefulWidget {
  const BackupView({super.key});

  @override
  State<BackupView> createState() => _BackupViewState();
}

class _BackupViewState extends State<BackupView> {
  final BackupService _service = BackupService.instance;
  bool _isLoading = false;
  String? _status;

  Future<void> _createBackup() async {
    final directory = await FilePicker.platform.getDirectoryPath();
    if (directory == null) { return; }

    setState(() {
      _isLoading = true;
      _status = 'Criando backup...';
    });

    try {
      final path = await _service.createBackup(directory);
      setState(() {
        _status = 'Backup criado: $path';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Erro: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (result == null || result.files.isEmpty) { return; }

    final path = result.files.single.path;
    if (path == null) { return; }

    setState(() {
      _isLoading = true;
      _status = 'Restaurando backup...';
    });

    try {
      final count = await _service.restoreBackup(path);
      setState(() {
        _status = '$count itens restaurados com sucesso!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Erro ao restaurar: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restauração')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.backup,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Criar Backup',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        'Salva suas músicas, playlists e configurações em um arquivo .zip.'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _createBackup,
                      icon: const Icon(Icons.save),
                      label: const Text('Criar Backup'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.restore,
                            size: 32,
                            color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Restaurar Backup',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        'Restaura dados de um arquivo de backup anterior.'),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _restoreBackup,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Selecionar Arquivo'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_status != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_status!, textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
    );
  }
}
