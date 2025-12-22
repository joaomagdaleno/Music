import 'package:flutter/material.dart';
import 'local_duo_service.dart';

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

  @override
  void initState() {
    super.initState();
    _service.onDeviceFound = (name) {
      setState(() {
        if (!_foundDevices.contains(name)) _foundDevices.add(name);
      });
    };
    _service.onConnected = (id) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conectado com sucesso!')),
        );
      }
    };
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
            const CircularProgressIndicator(),
            const SizedBox(height: 10),
            Text(_status ?? ""),
            if (_isDiscovering && _foundDevices.isEmpty)
              const Text("\nNenhum dispositivo encontrado ainda...",
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ..._foundDevices.map((d) => ListTile(
                  title: Text(d),
                  trailing: const Icon(Icons.link),
                  onTap: () {
                    // Connection is handled automatically in startDiscovery for now
                  },
                )),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                _service.stopAll();
                setState(() {
                  _isHosting = false;
                  _isDiscovering = false;
                  _foundDevices.clear();
                });
              },
              child: const Text('Cancelar'),
            )
          ],
        ],
      ),
    );
  }
}
