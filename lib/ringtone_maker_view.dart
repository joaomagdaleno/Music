import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'download_service.dart';

class RingtoneMakerView extends StatefulWidget {
  final SearchResult track;

  const RingtoneMakerView({super.key, required this.track});

  @override
  State<RingtoneMakerView> createState() => _RingtoneMakerViewState();
}

class _RingtoneMakerViewState extends State<RingtoneMakerView> {
  final AudioPlayer _player = AudioPlayer();
  RangeValues _currentRange = const RangeValues(0, 30);
  Duration _totalDuration = Duration.zero;
  bool _isPlayingSegment = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    if (widget.track.localPath != null) {
      final duration = await _player.setFilePath(widget.track.localPath!);
      setState(() {
        _totalDuration = duration ?? Duration.zero;
        // Default to first 30 seconds or full duration if shorter
        _currentRange = RangeValues(
            0,
            _totalDuration.inSeconds > 30
                ? 30
                : _totalDuration.inSeconds.toDouble());
      });
    }
  }

  void _playSegment() async {
    if (_isPlayingSegment) {
      await _player.pause();
      setState(() => _isPlayingSegment = false);
    } else {
      await _player.seek(Duration(seconds: _currentRange.start.toInt()));
      _player.play();
      setState(() => _isPlayingSegment = true);

      // Stop when it reaches the end of the range
      _player.positionStream.listen((pos) {
        if (pos.inSeconds >= _currentRange.end.toInt() && _isPlayingSegment) {
          _player.pause();
          if (mounted) { setState(() => _isPlayingSegment = false); }
        }
      });
    }
  }

  Future<void> _saveRingtone() async {
    // In a real app, we'd use a native plugin to cut the file.
    // For this expansion, we'll simulate the "Save" action with a success message.
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) { return; }
    Navigator.pop(context); // Close loading

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Toque "${widget.track.title}" (Corte) salvo com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ringtone Maker'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              // Album Art / Placeholder
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: NetworkImage(widget.track.thumbnail ??
                        'https://via.placeholder.com/150'),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                widget.track.title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                widget.track.artist,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              // Range Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(
                      Duration(seconds: _currentRange.start.toInt()))),
                  Text(
                      'Duração: ${(_currentRange.end - _currentRange.start).toInt()}s'),
                  Text(_formatDuration(
                      Duration(seconds: _currentRange.end.toInt()))),
                ],
              ),
              RangeSlider(
                values: _currentRange,
                min: 0,
                max: _totalDuration.inSeconds.toDouble() > 0
                    ? _totalDuration.inSeconds.toDouble()
                    : 100,
                divisions:
                    _totalDuration.inSeconds > 0 ? _totalDuration.inSeconds : 1,
                activeColor: Theme.of(context).colorScheme.primary,
                labels: RangeLabels(
                  _formatDuration(
                      Duration(seconds: _currentRange.start.toInt())),
                  _formatDuration(Duration(seconds: _currentRange.end.toInt())),
                ),
                onChanged: (values) {
                  // Ensure ringtone is between 5 and 40 seconds
                  final diff = values.end - values.start;
                  if (diff >= 5 && diff <= 40) {
                    setState(() => _currentRange = values);
                  }
                },
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    iconSize: 48,
                    icon: Icon(_isPlayingSegment
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded),
                    onPressed: _playSegment,
                  ),
                  const SizedBox(width: 24),
                  ElevatedButton.icon(
                    onPressed: _saveRingtone,
                    icon: const Icon(Icons.content_cut_rounded),
                    label: const Text('Exportar Toque'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Selecione entre 5 e 40 segundos para o seu toque.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
