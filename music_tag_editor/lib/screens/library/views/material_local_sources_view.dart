import 'package:flutter/material.dart';

/// Material Design view for LocalSourcesScreen
class MaterialLocalSourcesView extends StatelessWidget {
  final List<Map<String, dynamic>> folders;
  final bool isLoading;
  final bool isScanning;
  final String scanStatus;
  final VoidCallback onAddFolder;
  final void Function(String) onRemoveFolder;
  final VoidCallback onScanAll;

  const MaterialLocalSourcesView({
    super.key,
    required this.folders,
    required this.isLoading,
    required this.isScanning,
    required this.scanStatus,
    required this.onAddFolder,
    required this.onRemoveFolder,
    required this.onScanAll,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pastas de Música'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isScanning ? null : onScanAll,
            tooltip: 'Escanear todas as pastas',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAddFolder,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar Pasta'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (isScanning || scanStatus.isNotEmpty)
                  Container(
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        if (isScanning) ...[
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(child: Text(scanStatus)),
                      ],
                    ),
                  ),
                Expanded(
                  child: folders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.outline),
                              const SizedBox(height: 16),
                              const Text(
                                'Nenhuma pasta adicionada',
                                style: TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Toque no botão abaixo para adicionar uma pasta de músicas.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: folders.length,
                          itemBuilder: (context, index) {
                            final folder = folders[index];
                            final path = folder['path'] as String;
                            return ListTile(
                              leading: const Icon(Icons.folder),
                              title: Text(path.split(RegExp(r'[/\\]')).last),
                              subtitle: Text(path),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _confirmRemove(context, path),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _confirmRemove(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover pasta?'),
        content: Text('Deseja remover "$path" da lista de fontes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRemoveFolder(path);
            },
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}
