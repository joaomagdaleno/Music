import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'playback_service.dart';
import 'theme_service.dart';

class DiscoModeView extends StatefulWidget {
  const DiscoModeView({super.key});

  @override
  State<DiscoModeView> createState() => _DiscoModeViewState();
}

class _DiscoModeViewState extends State<DiscoModeView>
    with TickerProviderStateMixin {
  final PlaybackService _playback = PlaybackService.instance;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _barController;
  final Random _random = Random();

  List<double> _bars = List.generate(20, (i) => 0.3);
  Timer? _barTimer;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);

    _barController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _startBarAnimation();
  }

  void _startBarAnimation() {
    _barTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) { return; }
      setState(() {
        for (int i = 0; i < _bars.length; i++) {
          // Simulate audio reactivity with random values
          _bars[i] = 0.2 + _random.nextDouble() * 0.8;
        }
      });
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _barController.dispose();
    _barTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = _playback.currentTrack;
    final primaryColor = ThemeService.instance.primaryColor;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(
          children: [
            // Animated gradient background
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.5 + (_pulseController.value * 0.3),
                      colors: [
                        primaryColor.withValues(alpha: 0.4),
                        Colors.purple.withValues(alpha: 0.2),
                        Colors.black,
                      ],
                    ),
                  ),
                );
              },
            ),

            // Visualizer bars at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: _bars.asMap().entries.map((entry) {
                  final i = entry.key;
                  final value = entry.value;
                  final hue = (i / _bars.length * 60) +
                      (primaryColor.computeLuminance() * 180);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    width: MediaQuery.of(context).size.width / _bars.length - 4,
                    height: value * 180,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          HSLColor.fromAHSL(1, hue, 0.8, 0.5).toColor(),
                          HSLColor.fromAHSL(1, hue + 30, 0.9, 0.6).toColor(),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: HSLColor.fromAHSL(1, hue, 0.8, 0.5)
                              .toColor()
                              .withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // Rotating album art
            Center(
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * pi,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale = 1.0 + (_pulseController.value * 0.05);
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.5),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: track?.thumbnail != null
                                  ? Image.network(
                                      track!.thumbnail!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _buildPlaceholder(),
                                    )
                                  : _buildPlaceholder(),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // Track info overlay
            Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Text(
                    track?.title ?? 'No Track Playing',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    track?.artist ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Close hint
            Positioned(
              bottom: 220,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Toque para sair',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: const Icon(
        Icons.music_note,
        size: 80,
        color: Colors.white54,
      ),
    );
  }
}
