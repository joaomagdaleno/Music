import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_tag_editor/services/download_service.dart';
import 'package:music_tag_editor/screens/tracks/views/fluent_ringtone_maker_view.dart';
import 'package:music_tag_editor/screens/tracks/views/material_ringtone_maker_view.dart';

/// RingtoneMakerScreen controller - platform-adaptive
class RingtoneMakerScreen extends StatefulWidget {
  final SearchResult track;
  const RingtoneMakerScreen({super.key, required this.track});

  @override
  State<RingtoneMakerScreen> createState() => _RingtoneMakerScreenState();
}

class _RingtoneMakerScreenState extends State<RingtoneMakerScreen> {
  late AudioPlayer _player;
  RangeValues _currentRange = const RangeValues(0, 30);
  Duration _totalDuration = Duration.zero;
  bool _isPlayingSegment = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    if (widget.track.localPath != null) {
      final duration = await _player.setFilePath(widget.track.localPath!);
      setState(() {
        _totalDuration = duration ?? Duration.zero;
        _currentRange = RangeValues(0, _totalDuration.inSeconds > 30 ? 30 : _totalDuration.inSeconds.toDouble());
      });
    }
  }

  void _playSegment() async {
    if (_isPlayingSegment) { await _player.pause(); setState(() => _isPlayingSegment = false); }
    else {
      await _player.seek(Duration(seconds: _currentRange.start.toInt()));
      _player.play();
      setState(() => _isPlayingSegment = true);
      _player.positionStream.listen((pos) {
        if (pos.inSeconds >= _currentRange.end.toInt() && _isPlayingSegment) {
          _player.pause();
          if (mounted) setState(() => _isPlayingSegment = false);
        }
      });
    }
  }

  void _onRangeChanged(RangeValues values) {
    final diff = values.end - values.start;
    if (diff >= 5 && diff <= 40) setState(() => _currentRange = values);
  }

  void _save() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Toque salvo com sucesso!'), backgroundColor: Colors.green));
    Navigator.pop(context);
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final platform = defaultTargetPlatform;
    switch (platform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return FluentRingtoneMakerView(track: widget.track, currentRange: _currentRange, totalDuration: _totalDuration, isPlayingSegment: _isPlayingSegment, onPlaySegment: _playSegment, onSave: _save, onRangeChanged: _onRangeChanged, formatDuration: _formatDuration);
      default:
        return MaterialRingtoneMakerView(track: widget.track, currentRange: _currentRange, totalDuration: _totalDuration, isPlayingSegment: _isPlayingSegment, onPlaySegment: _playSegment, onSave: _save, onRangeChanged: _onRangeChanged, formatDuration: _formatDuration);
    }
  }
}
