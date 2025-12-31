import 'package:flutter/material.dart';

/// Material Design view for BackupScreen
class MaterialBackupView extends StatelessWidget {
  final bool isLoading;
  final String? lastBackupPath;
  final VoidCallback onCreateBackup;
  final VoidCallback onRestoreBackup;

  const MaterialBackupView({
    super.key,
    required this.isLoading,
    required this.lastBackupPath,
    required this.onCreateBackup,
    required this.onRestoreBackup,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restauração')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSection(context, 'Criar Backup', Icons.cloud_upload, 'Exporte sua biblioteca, playlists e configurações para um arquivo.', 'Criar Backup', onCreateBackup, Colors.blue),
                  const SizedBox(height: 16),
                  _buildSection(context, 'Restaurar Backup', Icons.cloud_download, 'Importe um arquivo de backup previamente criado.', 'Restaurar', onRestoreBackup, Colors.green),
                  if (lastBackupPath != null) ...[
                    const SizedBox(height: 16),
                    Card(child: ListTile(leading: const Icon(Icons.history), title: const Text('Último Backup'), subtitle: Text(lastBackupPath!))),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, String description, String buttonText, VoidCallback onPressed, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 28)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), Text(description, style: const TextStyle(color: Colors.grey))])),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(buttonText))),
          ],
        ),
      ),
    );
  }
}
