import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'playback_service.dart';
import 'download_service.dart';

class FloatingMiniPlayer extends StatefulWidget {
  const FloatingMiniPlayer({super.key});

  @override
  State<FloatingMiniPlayer> createState() => _FloatingMiniPlayerState();
}

class _FloatingMiniPlayerState extends State<FloatingMiniPlayer> {
  final PlaybackService _playback = PlaybackService.instance;

  @override
  void initState() {
    super.initState();
    _setupWindow();
  }

  Future<void> _setupWindow() async {
    if (!Platform.isWindows) return;

    await windowManager.ensureInitialized();
    await windowManager.setSize(const Size(320, 100));
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setResizable(false);
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setSkipTaskbar(true);
    await windowManager.show();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black.withOpacity(0.9),
      ),
      home: Scaffold(
        body: GestureDetector(
          onPanUpdate: (details) async {
            if (Platform.isWindows) {
              await windowManager.startDragging();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: StreamBuilder<SearchResult?>(
              stream: _playback.player.currentIndexStream
                  .map((_) => _playback.currentTrack),
              builder: (context, snapshot) {
                final track = _playback.currentTrack;

                return Row(
                  children: [
                    // Album Art
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(12)),
                      child: track?.thumbnail != null
                          ? Image.network(
                              track!.thumbnail!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[800],
                              child: const Icon(Icons.music_note,
                                  color: Colors.white54),
                            ),
                    ),
                    // Track Info & Controls
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track?.title ?? 'Sem música',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              track?.artist ?? '',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Playback Controls
                    StreamBuilder<bool>(
                      stream: _playback.player.playingStream,
                      builder: (context, snapshot) {
                        final isPlaying = snapshot.data ?? false;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.skip_previous,
                                  color: Colors.white70, size: 20),
                              onPressed: () =>
                                  _playback.player.seekToPrevious(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                                size: 28,
                              ),
                              onPressed: () {
                                if (isPlaying) {
                                  _playback.pause();
                                } else {
                                  _playback.resume();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_next,
                                  color: Colors.white70, size: 20),
                              onPressed: () => _playback.player.seekToNext(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.white54, size: 18),
                              onPressed: () async {
                                await windowManager.close();
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the floating mini player in a separate window.
Future<void> openFloatingMiniPlayer() async {
  // Note: Flutter doesn't natively support multi-window.
  // This would require platform-specific implementation or a separate process.
  // For now, this is a placeholder that could be enhanced with flutter_multi_window or similar.
  // The widget above is designed to be run as the main widget of a secondary window.

  // One approach on Windows is to spawn a separate Flutter process with a flag.
  // For simplicity, we'll document this as a future enhancement.
}
