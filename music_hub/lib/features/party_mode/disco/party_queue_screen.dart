import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:music_hub/features/party_mode/disco/views/fluent_party_queue_view.dart';
import 'package:music_hub/features/party_mode/disco/views/material_party_queue_view.dart';
import 'package:music_hub/core/services/notification_service.dart';

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


  void _showNotification(String message) {
    NotificationService.instance.show(context, message);
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
