import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:music_hub/core/services/local_duo_service.dart';

class DuoChatDialog extends StatefulWidget {
  const DuoChatDialog({super.key});

  @override
  State<DuoChatDialog> createState() => _DuoChatDialogState();
}

class _DuoChatDialogState extends State<DuoChatDialog> {
  final _service = LocalDuoService.instance;
  final _controller = TextEditingController();
  final List<String> _messages = [];

  @override
  void initState() {
    super.initState();
    _service.onMessageReceived = (msg) {
      if (mounted) {
        setState(() {
          _messages.add('Amigo: $msg');
        });
      }
    };
  }

  @override
  void dispose() {
    _service.onMessageReceived = null;
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_controller.text.isEmpty) {
      return;
    }
    _service.sendChatMessage(_controller.text);
    setState(() {
      _messages.add('Você: ${_controller.text}');
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Platform check
    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _buildFluent(context);
    }
    return _buildMaterial(context);
  }

  Widget _buildFluent(BuildContext context) => fluent.ContentDialog(
        title: const Text('Chat Duo (Offline)'),
        content: SizedBox(
          width: 400, // Fixed width for consistent look
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Envie mensagens via Bluetooth/Wi-Fi Direct',
                  style: TextStyle(fontSize: 12, color: fluent.Colors.grey)),
              const SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: fluent.FluentTheme.of(context)
                          .resources
                          .dividerStrokeColorDefault),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  shrinkWrap: true,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(_messages[index]),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: fluent.TextBox(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(),
                      placeholder: 'Digite uma mensagem...',
                    ),
                  ),
                  const SizedBox(width: 8),
                  fluent.IconButton(
                    icon: const Icon(fluent.FluentIcons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
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
        title: const Text('Chat Duo (Offline)'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Envie mensagens via Bluetooth/Wi-Fi Direct',
                  style: TextStyle(fontSize: 12, color: material.Colors.grey)),
              const material.Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(_messages[index]),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: material.TextField(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const material.InputDecoration(
                          hintText: 'Digite uma mensagem...'),
                    ),
                  ),
                  material.IconButton(
                    icon: const Icon(material.Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
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
}
