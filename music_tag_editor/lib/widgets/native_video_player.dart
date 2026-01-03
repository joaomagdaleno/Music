import 'package:fluent_ui/fluent_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:music_tag_editor/services/search_service.dart';
import 'package:music_tag_editor/services/startup_logger.dart';

class NativeVideoPlayer extends StatefulWidget {
  final String title;
  final String videoUrl;
  final Map<String, dynamic> videoDetails;

  const NativeVideoPlayer({
    super.key,
    required this.title,
    required this.videoUrl,
    required this.videoDetails,
  });

  @override
  State<NativeVideoPlayer> createState() => _NativeVideoPlayerState();
}

class _NativeVideoPlayerState extends State<NativeVideoPlayer> {
  late final Player _player = Player();
  late final VideoController _videoController = VideoController(_player);
  
  List<Map<String, String>> _resolutions = [];
  String _currentResolution = 'Auto';
  double _currentSpeed = 1.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _parseFormats();
      
      // Look for HLS manifest for "Auto" quality
      final hlsUrl = _getHlsUrl();
      if (hlsUrl != null) {
        await _player.open(Media(hlsUrl));
      } else {
        // Fallback to best available if no HLS
        final bestUrl = await SearchService.instance.getStreamUrl(widget.videoUrl);
        if (bestUrl != null) {
          await _player.open(Media(bestUrl));
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e, st) {
      StartupLogger.logError('[NativeVideoPlayer] Initialization failed', e, st);
    }
  }

  void _parseFormats() {
    final formats = widget.videoDetails['formats'] as List?;
    if (formats == null) return;

    final Map<String, Map<String, String>> uniqueResolutions = {};
    
    for (final f in formats) {
      final height = f['height'] as int?;
      if (height == null) continue;
      
      final label = '${height}p';
      if (!uniqueResolutions.containsKey(label)) {
        uniqueResolutions[label] = {
          'label': label,
          'url': f['url'] as String? ?? '',
        };
      }
    }

    _resolutions = uniqueResolutions.values.toList();
    _resolutions.sort((a, b) {
       final ha = int.tryParse(a['label']!.replaceAll('p', '')) ?? 0;
       final hb = int.tryParse(b['label']!.replaceAll('p', '')) ?? 0;
       return hb.compareTo(ha); // High to low
    });
  }

  String? _getHlsUrl() {
    final formats = widget.videoDetails['formats'] as List?;
    if (formats == null) return null;
    
    for (final f in formats) {
      if (f['protocol'] == 'm3u8_native' || (f['url'] as String).contains('.m3u8')) {
        return f['url'] as String;
      }
    }
    return null;
  }

  Future<void> _setResolution(String label) async {
    if (_currentResolution == label) return;

    setState(() {
      _currentResolution = label;
      _isLoading = true;
    });

    final position = _player.state.position;
    
    if (label == 'Auto') {
      final hlsUrl = _getHlsUrl();
      if (hlsUrl != null) {
        await _player.open(Media(hlsUrl));
      }
    } else {
      final res = _resolutions.firstWhere((r) => r['label'] == label);
      await _player.open(Media(res['url']!));
    }

    await _player.seek(position);
    await _player.setRate(_currentSpeed);
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: Text(widget.title),
      constraints: const BoxConstraints(maxWidth: 900),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Video(controller: _videoController),
                if (_isLoading)
                  const ProgressRing(),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildControls(),
        ],
      ),
      actions: [
        Button(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      children: [
        const Text('Qualidade: '),
        const SizedBox(width: 8),
        DropDownButton(
          title: Text(_currentResolution),
          items: [
            MenuFlyoutItem(
              text: const Text('Auto'),
              onPressed: () => _setResolution('Auto'),
            ),
            ..._resolutions.map((r) => MenuFlyoutItem(
              text: Text(r['label']!),
              onPressed: () => _setResolution(r['label']!),
            )),
          ],
        ),
        const Spacer(),
        const Text('Velocidade: '),
        const SizedBox(width: 8),
        DropDownButton(
          title: Text('${_currentSpeed}x'),
          items: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((s) => MenuFlyoutItem(
            text: Text('${s}x'),
            onPressed: () {
              setState(() => _currentSpeed = s);
              _player.setRate(s);
            },
          )).toList(),
        ),
      ],
    );
  }
}
