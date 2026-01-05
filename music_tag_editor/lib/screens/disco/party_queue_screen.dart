import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:music_tag_editor/screens/disco/views/fluent_party_queue_view.dart';
import 'package:music_tag_editor/screens/disco/views/material_party_queue_view.dart';

/// PartyQueueScreen controller - platform-adaptive
class PartyQueueScreen extends StatefulWidget {
  const PartyQueueScreen({super.key});

  @override
  State<PartyQueueScreen> createState() => _PartyQueueScreenState();
}

class _PartyQueueScreenState extends State<PartyQueueScreen> {
  bool _isSharing = false;
  final String _qrData = 'DUO_PARTY_SESSION_7788';

  void _toggleSharing() => setState(() => _isSharing = !_isSharing);

  void _scan() {
    _showNotification('Abrindo câmera para escanear...');
  }

  bool get _isFluent => defaultTargetPlatform == TargetPlatform.windows;

  void _showNotification(String message) {
    if (_isFluent) {
      fluent.displayInfoBar(context, builder: (context, close) {
        return fluent.InfoBar(
          title: Text(message),
          onClose: close,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    switch (platform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return FluentPartyQueueView(
            isSharing: _isSharing,
            qrData: _qrData,
            onToggleSharing: _toggleSharing,
            onScan: _scan);
      default:
        return MaterialPartyQueueView(
            isSharing: _isSharing,
            qrData: _qrData,
            onToggleSharing: _toggleSharing,
            onScan: _scan);
    }
  }
}
