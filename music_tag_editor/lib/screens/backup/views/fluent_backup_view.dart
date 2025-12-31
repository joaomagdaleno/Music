import 'package:fluent_ui/fluent_ui.dart';
import 'package:file_picker/file_picker.dart';

/// Fluent UI view for BackupScreen - WinUI 3 styling
class FluentBackupView extends StatelessWidget {
  final bool isLoading;
  final String? lastBackupPath;
  final VoidCallback onCreateBackup;
  final VoidCallback onRestoreBackup;

  const FluentBackupView({
    super.key,
    required this.isLoading,
    required this.lastBackupPath,
    required this.onCreateBackup,
    required this.onRestoreBackup,
  });

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(title: Text('Backup & Restauração')),
      content: isLoading
          ? const Center(child: ProgressRing())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(context, 'Criar Backup', FluentIcons.cloud_upload, 'Exporte sua biblioteca, playlists e configurações para um arquivo.', 'Criar Backup', onCreateBackup, Colors.blue),
                  const SizedBox(height: 24),
                  _buildSection(context, 'Restaurar Backup', FluentIcons.cloud_download, 'Importe um arquivo de backup previamente criado.', 'Restaurar', onRestoreBackup, Colors.green),
                  if (lastBackupPath != null) ...[
                    const SizedBox(height: 24),
                    Card(padding: const EdgeInsets.all(16), child: Row(children: [const Icon(FluentIcons.history, size: 24), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Último Backup', style: TextStyle(fontWeight: FontWeight.bold)), Text(lastBackupPath!, style: const TextStyle(fontSize: 12, color: Colors.grey))]))])),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, String description, String buttonText, VoidCallback onPressed, Color color) {
    return Card(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: FluentTheme.of(context).typography.subtitle),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          FilledButton(onPressed: onPressed, child: Text(buttonText)),
        ],
      ),
    );
  }
}
