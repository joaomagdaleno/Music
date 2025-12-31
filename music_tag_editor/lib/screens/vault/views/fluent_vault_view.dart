import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:music_tag_editor/services/download_service.dart';

/// Fluent UI view for VaultScreen - WinUI 3 styling
class FluentVaultView extends StatelessWidget {
  final bool isUnlocked;
  final List<SearchResult> tracks;
  final TextEditingController passwordController;
  final VoidCallback onUnlock;
  final VoidCallback onLock;
  final void Function(SearchResult) onPlayTrack;
  final void Function(SearchResult) onRemoveFromVault;

  const FluentVaultView({
    super.key,
    required this.isUnlocked,
    required this.tracks,
    required this.passwordController,
    required this.onUnlock,
    required this.onLock,
    required this.onPlayTrack,
    required this.onRemoveFromVault,
  });

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Cofre Privado'),
        commandBar: isUnlocked ? CommandBar(mainAxisAlignment: MainAxisAlignment.end, primaryItems: [
          CommandBarButton(icon: const Icon(FluentIcons.lock), label: const Text('Bloquear'), onPressed: onLock),
        ]) : null,
      ),
      content: !isUnlocked ? _buildUnlockView(context) : _buildVaultContent(context),
    );
  }

  Widget _buildUnlockView(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Card(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(FluentIcons.shield_alert, size: 64, color: fluent.Colors.orange),
              const SizedBox(height: 16),
              Text('Cofre Bloqueado', style: FluentTheme.of(context).typography.title),
              const SizedBox(height: 8),
              const Text('Digite sua senha para acessar músicas privadas.'),
              const SizedBox(height: 24),
              PasswordBox(controller: passwordController, placeholder: 'Senha'),
              const SizedBox(height: 16),
              FilledButton(onPressed: onUnlock, child: const Padding(padding: EdgeInsets.all(12), child: Text('Desbloquear'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVaultContent(BuildContext context) {
    if (tracks.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(FluentIcons.folder, size: 64, color: FluentTheme.of(context).inactiveColor), const SizedBox(height: 16), const Text('Seu cofre está vazio.')]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)), child: track.thumbnail != null ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(track.thumbnail!, fit: BoxFit.cover)) : const Icon(FluentIcons.music_note)),
            title: Text(track.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(track.artist),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(icon: const Icon(FluentIcons.play), onPressed: () => onPlayTrack(track)),
              IconButton(icon: const Icon(FluentIcons.lock_shield), onPressed: () => onRemoveFromVault(track)),
            ]),
          ),
        );
      },
    );
  }
}
