import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:music_hub/core/services/local_duo_service.dart';
import 'package:music_hub/features/library/screens/remote_library_screen.dart';
import 'package:music_hub/core/services/database_service.dart';
import 'package:music_hub/features/player/services/playback_service.dart';
import 'package:music_hub/features/library/models/search_models.dart';
import 'package:music_hub/features/party_mode/party_queue_screen.dart';

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
      if (mounted) {
        setState(() {
          if (!_foundDevices.contains(name)) _foundDevices.add(name);
        });
      }
    };
    _service.onConnected = (id) async {
      if (mounted) {
        final guestName = _service.getDiscoveredName(id) ?? 'Convidado';
        setState(() {
          _connectedGuests[id] = guestName;
          _status = 'Amigos Conectados: ${_connectedGuests.length}';
          _isHosting = _service.role == DuoRole.host;
          _isDiscovering = _service.role == DuoRole.guest;
        });

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
        _connectedGuests[id] = _service.getDiscoveredName(id) ?? 'Convidado';
      }
      if (_connectedGuests.isEmpty) {
        _status = null;
      } else {
        _status = 'Amigos Conectados: ${_connectedGuests.length}';
      }
    });
  }

  Future<void> _loadHistory() async {
    final history = await DatabaseService.instance.getGuestHistory();
    setState(() => _guestHistory = history);
  }

  Future<void> _startHost() async {
    final granted = await _service.requestPermissions();
    if (!granted) {
      return;
    }

    setState(() {
      _isHosting = true;
      _status = 'Aguardando amigo...';
    });
    await _service.startHost('Usuário ${DateTime.now().millisecond}');
  }

  Future<void> _startDiscovery() async {
    final granted = await _service.requestPermissions();
    if (!granted) {
      return;
    }

    setState(() {
      _isDiscovering = true;
      _status = 'Procurando amigos...';
    });
    await _service.startDiscovery('Usuário ${DateTime.now().millisecond}');
  }

  @override
  void dispose() {
    _service.onDeviceFound = null;
    _service.onConnected = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _buildFluent(context);
    }
    return _buildMaterial(context);
  }

  Widget _buildFluent(BuildContext context) => fluent.ContentDialog(
        title: const Text('Modo Duo (Sincronizar)'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Escute a mesma música com um amigo próximo.'),
              const SizedBox(height: 20),
              if (!_isHosting && !_isDiscovering) ...[
                fluent.Button(
                  onPressed: _startHost,
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(fluent.FluentIcons.wifi),
                        SizedBox(width: 8),
                        Text('Hospedar Sessão')
                      ]),
                ),
                const SizedBox(height: 10),
                fluent.Button(
                  onPressed: _startDiscovery,
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(fluent.FluentIcons.search),
                        SizedBox(width: 8),
                        Text('Entrar na Sessão')
                      ]),
                ),
                const SizedBox(height: 10),
                fluent.HyperlinkButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        fluent.FluentPageRoute(
                            builder: (context) => const PartyQueueScreen()));
                  },
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(fluent.FluentIcons.q_r_code),
                        SizedBox(width: 8),
                        Text('Fila de Festa (QR)')
                      ]),
                ),
              ] else ...[
                if (_connectedGuests.isNotEmpty) ...[
                  Center(
                      child: Icon(fluent.FluentIcons.group,
                          size: 48, color: fluent.Colors.green)),
                  const SizedBox(height: 10),
                  Text('Broadcast Ativo (${_connectedGuests.length})',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ..._connectedGuests.entries.map((e) => fluent.ListTile(
                        leading: const Icon(fluent.FluentIcons.people),
                        title: Text(e.value),
                        trailing: Icon(fluent.FluentIcons.check_mark,
                            color: fluent.Colors.green),
                      )),
                  const SizedBox(height: 20),
                  fluent.FilledButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          fluent.FluentPageRoute(
                              builder: (context) =>
                                  const RemoteLibraryScreen()));
                    },
                    child: const Text('Ver Músicas dos Amigos'),
                  ),
                ] else ...[
                  const fluent.ProgressRing(),
                  const SizedBox(height: 10),
                  Text(_status ?? '', textAlign: TextAlign.center),
                ],
                if (_isDiscovering &&
                    _foundDevices.isEmpty &&
                    _status != 'Conectado!')
                  const Text('\nNenhum dispositivo encontrado ainda...',
                      style: TextStyle(fontSize: 12, color: fluent.Colors.grey),
                      textAlign: TextAlign.center),
                if (_status != 'Conectado!')
                  ..._foundDevices.map((d) => fluent.ListTile(
                        title: Text(d),
                        trailing: const Icon(fluent.FluentIcons.link),
                        onPressed: () {},
                      )),
                const SizedBox(height: 20),
                fluent.Button(
                  onPressed: () {
                    _service.stopAll();
                    setState(() {
                      _isHosting = false;
                      _isDiscovering = false;
                      _foundDevices.clear();
                      _status = null;
                    });
                  },
                  child: Text(
                      _status == 'Conectado!' ? 'Desconectar' : 'Cancelar'),
                )
              ],
              if (!_isHosting &&
                  !_isDiscovering &&
                  _guestHistory.isNotEmpty) ...[
                const fluent.Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Histórico de Convidados',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _guestHistory.length,
                    itemBuilder: (context, index) {
                      final guest = _guestHistory[index];
                      return fluent.ListTile(
                        leading: const Icon(fluent.FluentIcons.people),
                        title: Text(guest['name']),
                        subtitle: Text(
                            'Última conexão: ${_formatDate(guest['last_connected'])}'),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          fluent.Button(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      );

  Widget _buildMaterial(BuildContext context) => material.AlertDialog(
        title: const Text('Modo Duo (Sincronizar)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Escute a mesma música com um amigo próximo.'),
              const SizedBox(height: 20),
              if (!_isHosting && !_isDiscovering) ...[
                material.ElevatedButton.icon(
                  icon: const Icon(material.Icons.wifi_tethering),
                  label: const Text('Hospedar Sessão'),
                  onPressed: _startHost,
                ),
                const SizedBox(height: 10),
                material.ElevatedButton.icon(
                  icon: const Icon(material.Icons.search),
                  label: const Text('Entrar na Sessão'),
                  onPressed: _startDiscovery,
                ),
                const SizedBox(height: 10),
                material.OutlinedButton.icon(
                  icon: const Icon(material.Icons.qr_code_scanner),
                  label: const Text('Fila de Festa (QR)'),
                  onPressed: () {
                    Navigator.push(
                        context,
                        material.MaterialPageRoute(
                            builder: (context) => const PartyQueueScreen()));
                  },
                ),
              ] else ...[
                if (_connectedGuests.isNotEmpty) ...[
                  const Icon(material.Icons.group,
                      color: material.Colors.green, size: 48),
                  const SizedBox(height: 10),
                  Text('Broadcast Ativo (${_connectedGuests.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ..._connectedGuests.entries.map((e) => material.ListTile(
                        leading: const Icon(material.Icons.person, size: 20),
                        title: Text(e.value),
                        trailing: const Icon(material.Icons.check,
                            color: material.Colors.green),
                      )),
                  const SizedBox(height: 20),
                  material.ElevatedButton.icon(
                    icon: const Icon(material.Icons.library_music),
                    label: const Text('Ver Músicas dos Amigos'),
                    onPressed: () {
                      Navigator.push(
                          context,
                          material.MaterialPageRoute(
                              builder: (context) =>
                                  const RemoteLibraryScreen()));
                    },
                  ),
                ] else ...[
                  const material.CircularProgressIndicator(),
                  const SizedBox(height: 10),
                  Text(_status ?? ''),
                ],
                if (_isDiscovering &&
                    _foundDevices.isEmpty &&
                    _status != 'Conectado!')
                  const Text('\nNenhum dispositivo encontrado ainda...',
                      style:
                          TextStyle(fontSize: 12, color: material.Colors.grey)),
                if (_status != 'Conectado!')
                  ..._foundDevices.map((d) => material.ListTile(
                        title: Text(d),
                        trailing: const Icon(material.Icons.link),
                        onTap: () {},
                      )),
                const SizedBox(height: 20),
                material.TextButton(
                  onPressed: () {
                    _service.stopAll();
                    setState(() {
                      _isHosting = false;
                      _isDiscovering = false;
                      _foundDevices.clear();
                      _status = null;
                    });
                  },
                  child: Text(
                      _status == 'Conectado!' ? 'Desconectar' : 'Cancelar'),
                )
              ],
              if (!_isHosting &&
                  !_isDiscovering &&
                  _guestHistory.isNotEmpty) ...[
                const material.Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Histórico de Convidados',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  height: 150,
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _guestHistory.length,
                    itemBuilder: (context, index) {
                      final guest = _guestHistory[index];
                      return material.ListTile(
                        leading: const Icon(material.Icons.person_outline),
                        title: Text(guest['name']),
                        subtitle: Text(
                            'Última conexão: ${_formatDate(guest['last_connected'])}'),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          material.TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      );

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}
