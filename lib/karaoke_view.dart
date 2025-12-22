import 'package:flutter/material.dart';
import 'dart:async';
import 'playback_service.dart';
import 'lyrics_service.dart';

class KaraokeView extends StatefulWidget {
  final Map<String, dynamic> track; // ID, Title, Artist

  const KaraokeView({super.key, required this.track});

  @override
  State<KaraokeView> createState() => _KaraokeViewState();
}

class _KaraokeViewState extends State<KaraokeView> {
  final PlaybackService _playbackService = PlaybackService.instance;
  final ScrollController _scrollController = ScrollController();
  int _activeLineIndex = -1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  void _startTracking() {
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) { return; }
      final pos = _playbackService.player.position.inMilliseconds;
      final lyrics = _playbackService.currentLyrics;

      int index = -1;
      for (int i = 0; i < lyrics.length; i++) {
        if (lyrics[i].time.inMilliseconds <= pos) {
          index = i;
        } else {
          break;
        }
      }

      if (index != _activeLineIndex && index != -1) {
        setState(() => _activeLineIndex = index);
        _scrollToActive();
      }
    });
  }

  void _scrollToActive() {
    if (_activeLineIndex != -1 && _scrollController.hasClients) {
      _scrollController.animateTo(
        _activeLineIndex * 80.0, // Approximate line height
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Gradient / Visualizer placeholder
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.5),
                radius: 1.5,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  Colors.black,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.track['title'] ?? 'Karaoke',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.track['artist'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<LyricLine>>(
                    stream: _playbackService.lyricsStream,
                    builder: (context, snapshot) {
                      final lyrics =
                          snapshot.data ?? _playbackService.currentLyrics;
                      if (lyrics.isEmpty) {
                        return const Center(
                          child: Text(
                            'Letras não sincronizadas...',
                            style: TextStyle(color: Colors.white54),
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            vertical: 300, horizontal: 32),
                        itemCount: lyrics.length,
                        itemBuilder: (context, index) {
                          final isActive = index == _activeLineIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 80,
                            alignment: Alignment.center,
                            child: Text(
                              lyrics[index].text,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isActive ? 32 : 24,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isActive ? Colors.white : Colors.white38,
                                shadows: isActive
                                    ? [
                                        Shadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          blurRadius: 10,
                                        )
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                // Playback controls simplified
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 48,
                        icon: const Icon(Icons.play_circle_filled,
                            color: Colors.white),
                        onPressed: () => _playbackService.resume(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
