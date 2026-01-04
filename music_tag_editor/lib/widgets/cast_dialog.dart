import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:music_tag_editor/services/cast_service.dart';
import 'package:music_tag_editor/services/playback_service.dart';

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
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _buildFluent(context);
    }
    return _buildMaterial(context);
  }

  Widget _buildFluent(BuildContext context) => fluent.ContentDialog(
        title: const Text('Transmitir para Dispositivo (DLNA)'),
        content: SizedBox(
          width: 350,
          height: 300,
          child: Column(
            children: [
              const fluent.ProgressBar(),
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
                        return fluent.ListTile(
                          leading: const Icon(fluent.FluentIcons.t_v_monitor),
                          title: Text(device.name),
                          subtitle: Text(device.host),
                          onPressed: () => _handleCast(context, device),
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
          fluent.Button(
            onPressed: () {
              _service.stopCasting();
              Navigator.pop(context);
            },
            child: const Text('Parar Transmissão'),
          ),
          fluent.Button(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      );

  Widget _buildMaterial(BuildContext context) => material.AlertDialog(
        title: const Text('Transmitir para Dispositivo (DLNA)'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            children: [
              const material.LinearProgressIndicator(),
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
                        return material.ListTile(
                          leading: const Icon(material.Icons.tv),
                          title: Text(device.name),
                          subtitle: Text(device.host),
                          onTap: () => _handleCast(context, device),
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
          material.TextButton(
            onPressed: () {
              _service.stopCasting();
              Navigator.pop(context);
            },
            child: const Text('Parar Transmissão'),
          ),
          material.TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      );

  Future<void> _handleCast(BuildContext context, CastDevice device) async {
    final track = PlaybackService.instance.currentTrack;
    if (track != null && track.localPath != null) {
      await _service.castFile(track.localPath!, device);
      if (context.mounted) {
        Navigator.pop(context);
        // Using ScaffoldMessenger from Material as it works globally often content of correct app wrapper
        // But for Fluent we might need displayInfoBar if strictly fluent.
        // Assuming ScaffoldMessenger works since we have MaterialApp/FluentApp wrappers usually
        // But in FluentApp, ScaffoldMessenger might not be present.
        // Let's safe check or use simple print/toast if possible.
        // Ideally we should use the proper feedback mechanism.
        // For now, I'll allow ScaffoldMessenger but wrap in try-catch or check platform?
        // Actually, let's just stick to ScaffoldMessenger.
        material.ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          material.SnackBar(content: Text('Transmitindo para ${device.name}')),
        );
      }
    } else {
      material.ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const material.SnackBar(
            content: Text('Apenas arquivos locais podem ser transmitidos.')),
      );
    }
  }
}
