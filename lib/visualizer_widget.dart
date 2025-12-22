import 'dart:math';
import 'package:flutter/material.dart';

class VisualizerWidget extends StatefulWidget {
  final bool isPlaying;
  final Color color;

  const VisualizerWidget(
      {super.key, required this.isPlaying, this.color = Colors.blue});

  @override
  State<VisualizerWidget> createState() => _VisualizerWidgetState();
}

class _VisualizerWidgetState extends State<VisualizerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _heights = List.generate(30, (_) => Random().nextDouble());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..repeat(reverse: true);
    if (!widget.isPlaying) _controller.stop();
  }

  @override
  void didUpdateWidget(VisualizerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 50),
          painter: _VisualizerPainter(
            heights: _heights,
            progress: _controller.value,
            color: widget.color.withOpacity(0.5),
          ),
        );
      },
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  final List<double> heights;
  final double progress;
  final Color color;

  _VisualizerPainter(
      {required this.heights, required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final barWidth = size.width / (heights.length * 2);

    for (int i = 0; i < heights.length; i++) {
      final x = i * barWidth * 2 + barWidth;
      final h = heights[i] * size.height * (0.5 + 0.5 * progress);
      canvas.drawLine(
        Offset(x, size.height / 2 - h / 2),
        Offset(x, size.height / 2 + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VisualizerPainter oldDelegate) => true;
}
