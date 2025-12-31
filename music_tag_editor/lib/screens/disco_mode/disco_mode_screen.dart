import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:music_tag_editor/services/playback_service.dart';
import 'package:music_tag_editor/services/theme_service.dart';

/// DiscoModeScreen controller - delegates to platform-specific views
/// For now, uses a single responsive view since it's a special fullscreen mode
class DiscoModeScreen extends StatefulWidget {
  const DiscoModeScreen({super.key});

  @override
  State<DiscoModeScreen> createState() => _DiscoModeScreenState();
}

class _DiscoModeScreenState extends State<DiscoModeScreen> {
  final PlaybackService _playbackService = PlaybackService.instance;
  final Random _random = Random();
  Timer? _colorTimer;
  Timer? _barTimer;
  Color _bgColor = Colors.purple;
  List<double> _barHeights = List.filled(32, 0.3);

  @override
  void initState() {
    super.initState();
    _startColorCycle();
    _startBarAnimation();
  }

  void _startColorCycle() {
    _colorTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {
          _bgColor = ThemeService.presetColors[_random.nextInt(ThemeService.presetColors.length)];
        });
      }
    });
  }

  void _startBarAnimation() {
    _barTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        setState(() {
          _barHeights = List.generate(32, (_) => 0.1 + _random.nextDouble() * 0.9);
        });
      }
    });
  }

  @override
  void dispose() {
    _colorTimer?.cancel();
    _barTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = _playbackService.currentTrack;

    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [_bgColor.withValues(alpha: 0.6), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Visualizer Bars
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _barHeights.map((h) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: 8,
                      height: MediaQuery.of(context).size.height * h * 0.6,
                      decoration: BoxDecoration(
                        color: _bgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Track Info & Controls
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (track?.thumbnail != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(track!.thumbnail!, width: 200, height: 200, fit: BoxFit.cover),
                      ),
                    const SizedBox(height: 32),
                    Text(track?.title ?? 'Modo Disco', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    Text(track?.artist ?? '', style: const TextStyle(color: Colors.white70, fontSize: 18)),
                    const SizedBox(height: 48),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(iconSize: 48, icon: const Icon(Icons.skip_previous, color: Colors.white), onPressed: () {}),
                        IconButton(
                          iconSize: 72,
                          icon: Icon(_playbackService.player.playing ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.white),
                          onPressed: () => _playbackService.player.playing ? _playbackService.pause() : _playbackService.resume(),
                        ),
                        IconButton(iconSize: 48, icon: const Icon(Icons.skip_next, color: Colors.white), onPressed: () {}),
                      ],
                    ),
                  ],
                ),
              ),
              // Close Button
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
