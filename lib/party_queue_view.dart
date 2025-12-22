import 'package:flutter/material.dart';

class PartyQueueView extends StatefulWidget {
  const PartyQueueView({super.key});

  @override
  State<PartyQueueView> createState() => _PartyQueueViewState();
}

class _PartyQueueViewState extends State<PartyQueueView> {
  bool _isSharing = false;
  final String _mockQrData = "DUO_PARTY_SESSION_7788";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fila de Festa (Party Queue)'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.tertiaryContainer,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_2_rounded,
                    size: 80, color: Colors.deepPurple),
                const SizedBox(height: 24),
                Text(
                  'Comece uma Festa',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Deixe seus amigos escanearem para adicionar músicas à fila em tempo real!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 48),
                if (!_isSharing)
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _isSharing = true),
                    icon: const Icon(Icons.share_arrival_time_rounded),
                    label: const Text('Gerar QR Code da Festa'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                  )
                else
                  Column(
                    children: [
                      // Simulated QR Code
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Image.network(
                          'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=$_mockQrData',
                          width: 200,
                          height: 200,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Código da Sessão: $_mockQrData',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _isSharing = false),
                        icon: const Icon(Icons.stop_circle_outlined),
                        label: const Text('Encerrar Festa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 48),
                OutlinedButton.icon(
                  onPressed: () {
                    // Simulate Scanning
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Abrindo câmera para escanear...')),
                    );
                  },
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Escanear QR de Amigo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
