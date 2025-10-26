import 'package:flutter/material.dart';

enum ConversionFormat { mp3, flac, wav, aac }

class ConversionDialog extends StatefulWidget {
  const ConversionDialog({super.key});

  @override
  State<ConversionDialog> createState() => _ConversionDialogState();
}

class _ConversionDialogState extends State<ConversionDialog> {
  ConversionFormat _selectedFormat = ConversionFormat.mp3;
  double _mp3Bitrate = 192;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Convert Audio'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Output Format:'),
          DropdownButton<ConversionFormat>(
            value: _selectedFormat,
            onChanged: (ConversionFormat? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedFormat = newValue;
                });
              }
            },
            items: const [
              DropdownMenuItem(value: ConversionFormat.mp3, child: Text('MP3')),
              DropdownMenuItem(value: ConversionFormat.flac, child: Text('FLAC')),
              DropdownMenuItem(value: ConversionFormat.wav, child: Text('WAV')),
              DropdownMenuItem(value: ConversionFormat.aac, child: Text('AAC')),
            ],
          ),
          if (_selectedFormat == ConversionFormat.mp3) ...[
            const SizedBox(height: 20),
            Text('MP3 Bitrate: ${_mp3Bitrate.toInt()} kbps'),
            Slider(
              value: _mp3Bitrate,
              min: 64,
              max: 320,
              divisions: 8,
              label: '${_mp3Bitrate.toInt()} kbps',
              onChanged: (double value) {
                setState(() {
                  _mp3Bitrate = value;
                });
              },
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop({
              'format': _selectedFormat,
              'mp3Bitrate': _mp3Bitrate,
            });
          },
          child: const Text('Start'),
        ),
      ],
    );
  }
}
