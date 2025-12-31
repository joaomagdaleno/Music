import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/lyrics_service.dart';
import 'package:music_tag_editor/screens/disco/views/fluent_karaoke_view.dart';
import 'package:music_tag_editor/screens/disco/views/material_karaoke_view.dart';

/// KaraokeScreen controller - platform-adaptive
class KaraokeScreen extends StatefulWidget {
  final Map<String, dynamic> track;
  const KaraokeScreen({super.key, required this.track});

  @override
  State<KaraokeScreen> createState() => _KaraokeScreenState();
}

class _KaraokeScreenState extends State<KaraokeScreen> {
  final _scrollController = ScrollController();
  int _activeLineIndex = -1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  void _startTracking() {
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      final pos = PlaybackService.instance.player.position.inMilliseconds;
      final lyrics = PlaybackService.instance.currentLyrics;
      int index = -1;
      for (int i = 0; i < lyrics.length; i++) {
        if (lyrics[i].time.inMilliseconds <= pos) index = i; else break;
      }
      if (index != _activeLineIndex && index != -1) {
        setState(() => _activeLineIndex = index);
        _scrollToActive();
      }
    });
  }

  void _scrollToActive() {
    if (_activeLineIndex != -1 && _scrollController.hasClients) {
      _scrollController.animateTo(_activeLineIndex * 80.0, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = PlaybackService.instance.currentLyrics;
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return FluentKaraokeView(track: widget.track, lyrics: lyrics, activeLineIndex: _activeLineIndex, scrollController: _scrollController, onResume: () => PlaybackService.instance.resume(), onClose: () => Navigator.pop(context));
      default:
        return MaterialKaraokeView(track: widget.track, lyrics: lyrics, activeLineIndex: _activeLineIndex, scrollController: _scrollController, onResume: () => PlaybackService.instance.resume(), onClose: () => Navigator.pop(context));
    }
  }
}
