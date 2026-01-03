import 'package:fluent_ui/fluent_ui.dart';

/// Fluent UI view for LocalSourcesScreen
class FluentLocalSourcesView extends StatelessWidget {
  final List<Map<String, dynamic>> folders;
  final bool isLoading;
  final bool isScanning;
  final String scanStatus;
  final VoidCallback onAddFolder;
  final void Function(String) onRemoveFolder;
  final VoidCallback onScanAll;

  const FluentLocalSourcesView({
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
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Pastas de Música'),
        leading: Navigator.canPop(context)
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: IconButton(
                  icon: const Icon(FluentIcons.back),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            : null,
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.add),
              label: const Text('Adicionar Pasta'),
              onPressed: onAddFolder,
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Escanear Todas'),
              onPressed: isScanning ? null : onScanAll,
            ),
          ],
        ),
      ),
      content: isLoading
          ? const Center(child: ProgressRing())
          : Column(
              children: [
                if (isScanning || scanStatus.isNotEmpty)
                  Container(
                    width: double.infinity,
                    color: FluentTheme.of(context).accentColor.withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        if (isScanning) ...[
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: ProgressRing(strokeWidth: 2),
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
                              Icon(FluentIcons.folder_open,
                                  size: 64,
                                  color: FluentTheme.of(context).inactiveColor),
                              const SizedBox(height: 16),
                              const Text(
                                'Nenhuma pasta adicionada',
                                style: TextStyle(fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Clique em "Adicionar Pasta" para importar músicas.',
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
                              leading: const Icon(FluentIcons.folder),
                              title: Text(path.split(RegExp(r'[/\\]')).last),
                              subtitle: Text(path),
                              trailing: IconButton(
                                icon: const Icon(FluentIcons.delete),
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
      builder: (_) => ContentDialog(
        title: const Text('Remover pasta?'),
        content: Text('Deseja remover "$path" da lista de fontes?'),
        actions: [
          Button(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
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
