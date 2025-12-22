import 'package:flutter/material.dart';
import 'cast_service.dart';
import 'playback_service.dart';

class CastDialog extends StatefulWidget {
  const CastDialog({super.key});

  @override
  State<CastDialog> createState() => _CastDialogState();
}

class _CastDialogState extends State<CastDialog> {
  final _service = CastService.instance;

  @override
  void initState() {
    super.initState();
    _service.startDiscovery();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Transmitir para Dispositivo (DLNA)'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: Column(
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<CastDevice>>(
                stream: _service.devicesStream,
                initialData: const [],
                builder: (context, snapshot) {
                  final devices = snapshot.data ?? [];
                  if (devices.isEmpty) {
                    return const Center(
                        child: Text('Procurando dispositivos...'));
                  }
                  return ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return ListTile(
                        leading: const Icon(Icons.tv),
                        title: Text(device.name),
                        subtitle: Text(device.host),
                        onTap: () async {
                          final track = PlaybackService.instance.currentTrack;
                          if (track != null && track.localPath != null) {
                            await _service.castFile(track.localPath!, device);
                            if (mounted) Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Transmitindo para ${device.name}')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Apenas arquivos locais podem ser transmitidos.')),
                            );
                          }
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _service.stopCasting();
            Navigator.pop(context);
          },
          child: const Text('Parar Transmissão'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
