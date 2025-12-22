import 'package:flutter/material.dart';
import 'database_service.dart';
import 'download_service.dart';
import 'security_service.dart';
import 'playback_service.dart';

class VaultView extends StatefulWidget {
  const VaultView({super.key});

  @override
  State<VaultView> createState() => _VaultViewState();
}

class _VaultViewState extends State<VaultView> {
  final DatabaseService _db = DatabaseService.instance;
  final SecurityService _security = SecurityService.instance;
  final _passwordController = TextEditingController();

  bool _isUnlocked = false;
  List<SearchResult> _vaultTracks = [];
  bool _isLoading = false;

  Future<void> _unlock() async {
    final password = _passwordController.text;
    final success = await _security.unlockVault(password);

    if (success) {
      setState(() {
        _isUnlocked = true;
        _isLoading = true;
      });
      _loadVaultTracks();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha incorreta')),
        );
      }
    }
  }

  Future<void> _loadVaultTracks() async {
    final allTracks = await _db.getAllTracks();
    setState(() {
      _vaultTracks = allTracks.where((t) => t.isVault).toList();
      _isLoading = false;
    });
  }

  Future<void> _removeFromVault(SearchResult track) async {
    await _db.toggleVault(track.id, false);
    _loadVaultTracks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${track.title} removida do cofre')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUnlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cofre Privado')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 64, color: Colors.amber),
                const SizedBox(height: 24),
                const Text(
                  'Este espaço é protegido por senha',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Senha do Cofre',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _unlock(),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _unlock,
                  child: const Text('Desbloquear'),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    // Logic to trigger 2FA recovery flow could go here
                  },
                  child: const Text('Esqueceu a senha? Use Recuperação 2FA'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Músicas no Cofre')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vaultTracks.isEmpty
              ? const Center(child: Text('Nenhuma música no cofre'))
              : ListView.builder(
                  itemCount: _vaultTracks.length,
                  itemBuilder: (context, index) {
                    final track = _vaultTracks[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: track.thumbnail != null
                            ? Image.network(track.thumbnail!,
                                width: 50, height: 50, fit: BoxFit.cover)
                            : const Icon(Icons.music_note),
                      ),
                      title: Text(track.title),
                      subtitle: Text(track.artist),
                      trailing: IconButton(
                        icon: const Icon(Icons.lock_open, color: Colors.blue),
                        onPressed: () => _removeFromVault(track),
                        tooltip: 'Remover do Cofre',
                      ),
                      onTap: () =>
                          PlaybackService.instance.playSearchResult(track),
                    );
                  },
                ),
    );
  }
}
