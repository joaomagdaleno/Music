import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';

import 'package:music_tag_editor/screens/disco/views/fluent_disco_view.dart';
import 'package:music_tag_editor/screens/disco/views/material_disco_view.dart';

/// DiscoModeScreen controller - platform-adaptive
class DiscoModeScreen extends StatefulWidget {
  const DiscoModeScreen({super.key});

  @override
  State<DiscoModeScreen> createState() => _DiscoModeScreenState();
}

class _DiscoModeScreenState extends State<DiscoModeScreen> {
  final Random _random = Random();
  final List<double> _bars = List.generate(20, (i) => 0.3);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        setState(() {
          for (int i = 0; i < _bars.length; i++) {
            _bars[i] = 0.2 + _random.nextDouble() * 0.8;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = PlaybackService.instance.currentTrack;
    final primaryColor = ThemeService.instance.primaryColor;
    final platform = defaultTargetPlatform;

    switch (platform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return FluentDiscoModeView(
            currentTrack: track,
            bars: _bars,
            primaryColor: primaryColor,
            onTap: () => Navigator.pop(context));
      default:
        return MaterialDiscoModeView(
            currentTrack: track,
            bars: _bars,
            primaryColor: primaryColor,
            onTap: () => Navigator.pop(context));
    }
  }
}
