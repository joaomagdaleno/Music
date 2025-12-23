import 'package:flutter/material.dart';
import 'package:music_tag_editor/services/local_duo_service.dart';
import 'package:music_tag_editor/views/remote_library_view.dart';
import 'package:music_tag_editor/services/database_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/download_service.dart'; // For SearchResult
import 'package:music_tag_editor/views/party_queue_view.dart';

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
  final Map<String, String> _connectedGuests = {};
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
        final guestName = _service.getDiscoveredName(id) ?? "Convidado";
        setState(() {
          _connectedGuests[id] = guestName;
          _status = "Amigos Conectados: ${_connectedGuests.length}";
          _isHosting = _service.role == DuoRole.host;
          _isDiscovering = _service.role == DuoRole.guest;
        });

        // Restore session tracks (only if just one guest or first connection)
        if (_connectedGuests.length == 1) {
          final tracks = await DatabaseService.instance.getDuoSessionTracks(id);
          for (var t in tracks) {
            final result = SearchResult.fromJson(t);
            PlaybackService.instance.addToQueue(result);
          }
        }
      }
    };
    _service.onDisconnected = () {
      if (mounted) {
        _loadConnectedGuests();
      }
    };
  }

  void _loadConnectedGuests() {
    setState(() {
      _connectedGuests.clear();
      for (var id in _service.connectedEndpoints) {
        _connectedGuests[id] = _service.getDiscoveredName(id) ?? "Convidado";
      }
      if (_connectedGuests.isEmpty) {
        _status = null;
      } else {
        _status = "Amigos Conectados: ${_connectedGuests.length}";
      }
    });
  }

  Future<void> _loadHistory() async {
    final history = await DatabaseService.instance.getGuestHistory();
    setState(() => _guestHistory = history);
  }

  Future<void> _startHost() async {
    final granted = await _service.requestPermissions();
    if (!granted) { return; }

    setState(() {
      _isHosting = true;
      _status = "Aguardando amigo...";
    });
    await _service.startHost("Usuário ${DateTime.now().millisecond}");
  }

  Future<void> _startDiscovery() async {
    final granted = await _service.requestPermissions();
    if (!granted) { return; }

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
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Fila de Festa (QR)'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PartyQueueView()),
                );
              },
            ),
          ] else ...[
            if (_connectedGuests.isNotEmpty) ...[
              const Icon(Icons.group, color: Colors.green, size: 48),
              const SizedBox(height: 10),
              Text("Broadcast Ativo (${_connectedGuests.length})",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ..._connectedGuests.entries.map((e) => ListTile(
                    leading: const Icon(Icons.person, size: 20),
                    title: Text(e.value),
                    trailing: const Icon(Icons.check, color: Colors.green),
                  )),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.library_music),
                label: const Text('Ver Músicas dos Amigos'),
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

