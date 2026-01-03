import 'package:fluent_ui/fluent_ui.dart';

/// Fluent UI view for PartyQueueScreen - WinUI 3 styling
class FluentPartyQueueView extends StatelessWidget {
  final bool isSharing;
  final String qrData;
  final VoidCallback onToggleSharing;
  final VoidCallback onScan;

  const FluentPartyQueueView({
    super.key,
    required this.isSharing,
    required this.qrData,
    required this.onToggleSharing,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Fila de Festa (Party Queue)'),
        leading: Navigator.canPop(context)
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: IconButton(
                  icon: const Icon(FluentIcons.back),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            : null,
      ),
      content: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(48.0),
            child: Column(
              children: [
                Icon(FluentIcons.contact_card, size: 100, color: Colors.purple),
                const SizedBox(height: 24),
                Text('Comece uma Festa', style: FluentTheme.of(context).typography.title),
                const SizedBox(height: 12),
                const Text('Deixe seus amigos escanearem para adicionar músicas à fila em tempo real!', textAlign: TextAlign.center),
                const SizedBox(height: 48),
                if (!isSharing)
                  FilledButton(onPressed: onToggleSharing, child: const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12), child: Text('Gerar QR Code da Festa')))
                else
                  _buildSharingView(context),
                const SizedBox(height: 48),
                Button(onPressed: onScan, child: const Text('Escanear QR de Amigo')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSharingView(BuildContext context) {
    return Column(
      children: [
        Card(
          padding: const EdgeInsets.all(16),
          child: Image.network(
            'https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=$qrData',
            width: 200, height: 200,
            errorBuilder: (_, __, ___) => const Icon(FluentIcons.contact_card, size: 100),
          ),
        ),
        const SizedBox(height: 24),
        Text('Código da Sessão: $qrData', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
        const SizedBox(height: 32),
        Button(onPressed: onToggleSharing, child: const Text('Encerrar Festa')),
      ],
    );
  }
}
