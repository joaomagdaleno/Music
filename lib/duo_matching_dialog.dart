import 'package:flutter/material.dart';
import 'local_duo_service.dart';
import 'remote_library_view.dart';
import 'database_service.dart';
import 'playback_service.dart';
import 'download_service.dart'; // For SearchResult

class DuoMatchingDialog extends StatefulWidget {
  const DuoMatchingDialog({super.key});

  @override
  State<DuoMatchingDialog> createState() => _DuoMatchingDialogState();
}

class _DuoMatchingDialogState extends State<DuoMatchingDialog> {
  final _service = LocalDuoService.instance;
  bool _isHosting = false;
  bool _isDiscovering = false;
  String? _status;
  final List<String> _foundDevices = [];
  List<Map<String, dynamic>> _guestHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _service.onDeviceFound = (name) {
      setState(() {
        if (!_foundDevices.contains(name)) _foundDevices.add(name);
      });
    };
    _service.onConnected = (id) async {
      if (mounted) {
        setState(() {
          _status = "Conectado!";
          _isHosting = false;
          _isDiscovering = false;
        });

        // Restore session tracks
        final tracks = await DatabaseService.instance.getDuoSessionTracks(id);
        for (var t in tracks) {
          final result = SearchResult.fromJson(
              t); // Maps are close enough to JSON for our fromJson
          PlaybackService.instance.addToQueue(result);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Conectado! ${tracks.length} músicas da última sessão restauradas.')),
        );
      }
    };
  }

  Future<void> _loadHistory() async {
    final history = await DatabaseService.instance.getGuestHistory();
    setState(() => _guestHistory = history);
  }

  Future<void> _startHost() async {
    final granted = await _service.requestPermissions();
    if (!granted) return;

    setState(() {
      _isHosting = true;
      _status = "Aguardando amigo...";
    });
    await _service.startHost("Usuário ${DateTime.now().millisecond}");
  }

  Future<void> _startDiscovery() async {
    final granted = await _service.requestPermissions();
    if (!granted) return;

    setState(() {
      _isDiscovering = true;
      _status = "Procurando amigos...";
    });
    await _service.startDiscovery("Usuário ${DateTime.now().millisecond}");
  }

  @override
  void dispose() {
    _service.onDeviceFound = null;
    _service.onConnected = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Modo Duo (Sincronizar)'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Escute a mesma música com um amigo próximo.'),
          const SizedBox(height: 20),
          if (!_isHosting && !_isDiscovering) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.wifi_tethering),
              label: const Text('Hospedar Sessão'),
              onPressed: _startHost,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Entrar na Sessão'),
              onPressed: _startDiscovery,
            ),
          ] else ...[
            if (_status == "Conectado!") ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 10),
              const Text("Modo Duo Ativo",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.library_music),
                label: const Text('Ver Músicas do Amigo'),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RemoteLibraryView()));
                },
              ),
            ] else ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              Text(_status ?? ""),
            ],
            if (_isDiscovering &&
                _foundDevices.isEmpty &&
                _status != "Conectado!")
              const Text("\nNenhum dispositivo encontrado ainda...",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            if (_status != "Conectado!")
              ..._foundDevices.map((d) => ListTile(
                    title: Text(d),
                    trailing: const Icon(Icons.link),
                    onTap: () {
                      // Connection is handled automatically in startDiscovery for now
                    },
                  )),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                _service.stopAll();
                setState(() {
                  _isHosting = false;
                  _isDiscovering = false;
                  _foundDevices.clear();
                  _status = null;
                });
              },
              child: Text(_status == "Conectado!" ? 'Desconectar' : 'Cancelar'),
            )
          ],
          if (!_isHosting && !_isDiscovering && _guestHistory.isNotEmpty) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Histórico de Convidados',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              height: 150,
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: _guestHistory.length,
                itemBuilder: (context, index) {
                  final guest = _guestHistory[index];
                  return ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(guest['name']),
                    subtitle: Text(
                        'Última conexão: ${_formatDate(guest['last_connected'])}'),
                    onTap: () {
                      // Maybe show what was in that session?
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}
