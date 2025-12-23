import 'package:flutter/material.dart';
import 'package:music_tag_editor/services/local_duo_service.dart';

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
          _messages.add("Amigo: $msg");
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
    if (_controller.text.isEmpty) { return; }
    _service.sendChatMessage(_controller.text);
    setState(() {
      _messages.add("Você: ${_controller.text}");
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chat Duo (Offline)'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Envie mensagens via Bluetooth/Wi-Fi Direct',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(),
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
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                        hintText: 'Digite uma mensagem...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

