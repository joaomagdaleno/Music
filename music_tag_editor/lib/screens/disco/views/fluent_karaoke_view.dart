import 'package:fluent_ui/fluent_ui.dart';
import 'package:music_tag_editor/services/lyrics_service.dart';

/// Fluent UI view for KaraokeScreen - WinUI 3 styling
class FluentKaraokeView extends StatelessWidget {
  final Map<String, dynamic> track;
  final List<LyricLine> lyrics;
  final int activeLineIndex;
  final ScrollController scrollController;
  final VoidCallback onResume;
  final VoidCallback onClose;

  const FluentKaraokeView({
    super.key,
    required this.track,
    required this.lyrics,
    required this.activeLineIndex,
    required this.scrollController,
    required this.onResume,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.black,
        child: Stack(
          children: [
            _buildGlow(context),
            _buildHeader(),
            _buildLyrics(context),
            _buildControls(),
          ],
        ),
      );

  Widget _buildGlow(BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.5),
            radius: 1.5,
            colors: [
              FluentTheme.of(context).accentColor.withValues(alpha: 0.3),
              Colors.black
            ],
          ),
        ),
      );

  Widget _buildHeader() => Positioned(
        top: 40,
        left: 24,
        right: 24,
        child: Row(
          children: [
            IconButton(
                icon: const Icon(FluentIcons.chrome_close, color: Colors.white),
                onPressed: onClose),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(track['title'] ?? 'Karaoke',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          decoration: TextDecoration.none)),
                  Text(track['artist'] ?? '',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          decoration: TextDecoration.none)),
                ])),
          ],
        ),
      );

  Widget _buildLyrics(BuildContext context) {
    if (lyrics.isEmpty)
      return Center(
          child: Text('Letras não sincronizadas...',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  decoration: TextDecoration.none)));

    return ListView.builder(
      controller: scrollController,
      itemExtent: 100.0, // ⚡ Bolt: Fixed extent for efficient scrolling
      padding: const EdgeInsets.symmetric(vertical: 400, horizontal: 48),
      itemCount: lyrics.length,
      itemBuilder: (context, index) {
        final isActive = index == activeLineIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 100,
          alignment: Alignment.center,
          child: Text(
            lyrics[index].text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isActive ? 40 : 28,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color:
                  isActive ? Colors.white : Colors.white.withValues(alpha: 0.3),
              decoration: TextDecoration.none,
              shadows: isActive
                  ? [
                      Shadow(
                          color: FluentTheme.of(context).accentColor,
                          blurRadius: 15)
                    ]
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() => Positioned(
        bottom: 40,
        left: 0,
        right: 0,
        child: Center(
          child: IconButton(
            icon: const Icon(FluentIcons.play, size: 48, color: Colors.white),
            onPressed: onResume,
          ),
        ),
      );
}
