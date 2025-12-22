import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'download_service.dart';
import 'dependency_manager.dart';

/// Page for downloading music from YouTube, YouTube Music, and Spotify.
class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final _urlController = TextEditingController();
  final _downloadService = DownloadService();

  bool _isLoading = false;
  bool _isInitializing = true;
  String _initStatus = 'Checking dependencies...';
  double _initProgress = 0;

  MediaInfo? _mediaInfo;
  DownloadFormat? _selectedFormat;
  String? _errorMessage;

  double _downloadProgress = 0;
  String _downloadStatus = '';
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _initDependencies();
  }

  Future<void> _initDependencies() async {
    try {
      await DependencyManager.instance.ensureDependencies(
        onProgress: (status, progress) {
          setState(() {
            _initStatus = status;
            _initProgress = progress;
          });
        },
      );
      setState(() => _isInitializing = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _fetchInfo() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _mediaInfo = null;
      _selectedFormat = null;
    });

    try {
      final info = await _downloadService.getMediaInfo(url);
      setState(() {
        _mediaInfo = info;
        _selectedFormat = info.formats.isNotEmpty ? info.formats.first : null;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startDownload() async {
    if (_mediaInfo == null || _selectedFormat == null) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _downloadStatus = 'Starting...';
    });

    try {
      // Use user's Music folder as default
      final musicDir = '${Platform.environment['USERPROFILE']}\\Music';

      await _downloadService.download(
        _urlController.text.trim(),
        _selectedFormat!,
        musicDir,
        onProgress: (progress, status) {
          setState(() {
            _downloadProgress = progress;
            _downloadStatus = status;
          });
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download complete!')),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Download failed: $e');
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _urlController.text = data!.text!;
      _fetchInfo();
    }
  }

  Widget _buildPlatformIcon(MediaPlatform platform) {
    IconData icon;
    Color color;

    switch (platform) {
      case MediaPlatform.youtube:
        icon = Icons.play_circle_fill;
        color = Colors.red;
      case MediaPlatform.youtubeMusic:
        icon = Icons.music_note;
        color = Colors.red;
      case MediaPlatform.spotify:
        icon = Icons.music_note;
        color = Colors.green;
      case MediaPlatform.hifi:
        icon = Icons.high_quality;
        color = Colors.purple;
      case MediaPlatform.unknown:
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 24);
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Download Music')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(_initStatus),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: _initProgress),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Music'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // URL Input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Paste a URL from YouTube, YouTube Music, or Spotify',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _urlController,
                            decoration: InputDecoration(
                              hintText: 'https://...',
                              border: const OutlineInputBorder(),
                              prefixIcon: _buildPlatformIcon(_downloadService
                                  .detectPlatform(_urlController.text)),
                            ),
                            onSubmitted: (_) => _fetchInfo(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _pasteFromClipboard,
                          icon: const Icon(Icons.paste),
                          tooltip: 'Paste from clipboard',
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _isLoading ? null : _fetchInfo,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.search),
                          label: const Text('Fetch'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Error Message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ),
            ],

            // Media Info
            if (_mediaInfo != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_mediaInfo!.thumbnail != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _mediaInfo!.thumbnail!,
                                width: 120,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 120,
                                  height: 90,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.music_note),
                                ),
                              ),
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _mediaInfo!.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_mediaInfo!.artist != null)
                                  Text(_mediaInfo!.artist!),
                                const SizedBox(height: 4),
                                Chip(
                                    label: Text(_mediaInfo!.platform.name
                                        .toUpperCase())),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select Format:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<DownloadFormat>(
                        initialValue: _selectedFormat,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: _mediaInfo!.formats.map((f) {
                          return DropdownMenuItem(
                            value: f,
                            child: Row(
                              children: [
                                Icon(
                                  f.isAudioOnly
                                      ? Icons.audiotrack
                                      : Icons.videocam,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(f.displayName),
                                if (f.filesize != null)
                                  Text(
                                    ' (${(f.filesize! / 1024 / 1024).toStringAsFixed(1)} MB)',
                                    style:
                                        TextStyle(color: Colors.grey.shade600),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (f) => setState(() => _selectedFormat = f),
                      ),
                      const SizedBox(height: 16),
                      if (_isDownloading) ...[
                        LinearProgressIndicator(value: _downloadProgress),
                        const SizedBox(height: 8),
                        Text(_downloadStatus),
                      ] else
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed:
                                _selectedFormat != null ? _startDownload : null,
                            icon: const Icon(Icons.download),
                            label: const Text('Download'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}
