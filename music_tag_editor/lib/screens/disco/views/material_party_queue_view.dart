import 'package:flutter/material.dart';

/// Material Design view for PartyQueueScreen
class MaterialPartyQueueView extends StatelessWidget {
  final bool isSharing;
  final String qrData;
  final VoidCallback onToggleSharing;
  final VoidCallback onScan;

  const MaterialPartyQueueView({
    super.key,
    required this.isSharing,
    required this.qrData,
    required this.onToggleSharing,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Party Queue')),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_2, size: 80, color: Colors.deepPurple),
                const SizedBox(height: 24),
                Text('Comece uma Festa', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                const Text('Escaneie para adicionar músicas!', textAlign: TextAlign.center),
                const SizedBox(height: 48),
                if (!isSharing)
                  ElevatedButton(onPressed: onToggleSharing, child: const Text('Gerar QR Code'))
                else
                  _buildSharingView(),
                const SizedBox(height: 32),
                OutlinedButton(onPressed: onScan, child: const Text('Escanear Amigo')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSharingView() {
    return Column(
      children: [
        Image.network('https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$qrData', width: 150),
        const SizedBox(height: 16),
        Text('Sessão: $qrData', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextButton(onPressed: onToggleSharing, child: const Text('Encerrar', style: TextStyle(color: Colors.red))),
      ],
    );
  }
}
