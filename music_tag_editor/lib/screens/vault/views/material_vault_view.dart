import 'package:flutter/material.dart';
import 'package:music_tag_editor/services/download_service.dart';

/// Material Design view for VaultScreen
class MaterialVaultView extends StatelessWidget {
  final bool isUnlocked;
  final List<SearchResult> tracks;
  final TextEditingController passwordController;
  final VoidCallback onUnlock;
  final VoidCallback onLock;
  final void Function(SearchResult) onPlayTrack;
  final void Function(SearchResult) onRemoveFromVault;

  const MaterialVaultView({
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cofre Privado'),
        actions: isUnlocked ? [IconButton(icon: const Icon(Icons.lock), onPressed: onLock)] : null,
      ),
      body: !isUnlocked ? _buildUnlockView(context) : _buildVaultContent(context),
    );
  }

  Widget _buildUnlockView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 64, color: Colors.amber),
            const SizedBox(height: 24),
            const Text('Cofre Bloqueado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Senha do Cofre', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onUnlock, child: const Text('Desbloquear')),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultContent(BuildContext context) {
    if (tracks.isEmpty) return const Center(child: Text('Nenhuma música no cofre'));
    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return ListTile(
          leading: track.thumbnail != null ? ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(track.thumbnail!, width: 40, height: 40, fit: BoxFit.cover)) : const Icon(Icons.music_note),
          title: Text(track.title),
          subtitle: Text(track.artist),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.play_arrow), onPressed: () => onPlayTrack(track)),
              IconButton(icon: const Icon(Icons.lock_open), onPressed: () => onRemoveFromVault(track)),
            ],
          ),
          onTap: () => onPlayTrack(track),
        );
      },
    );
  }
}
