import 'package:flutter/material.dart';

class SpectrogramPainter extends CustomPainter {
  final List<double> magnitudes;
  final Color baseColor;

  SpectrogramPainter({
    required this.magnitudes,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (magnitudes.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.fill;

    final barWidth = size.width / magnitudes.length;
    
    // Draw from left to right (low freq to high freq)
    for (int i = 0; i < magnitudes.length; i++) {
      final mag = magnitudes[i];
      // Altura da barra baseada na magnitude (normalizada 0.0 - 1.0)
      final barHeight = mag * size.height;
      
      // Aplicar um gradiente de opacidade/cor baseado na frequência (x) e altura (y)
      // Frequencias mais altas (direita) ficam um pouco mais claras se a magnitude for alta
      final intensity = mag.clamp(0.0, 1.0);
      paint.color = baseColor.withOpacity(0.3 + (intensity * 0.7));

      final rect = Rect.fromLTWH(
        i * barWidth,
        size.height - barHeight,
        barWidth > 1.0 ? barWidth - 0.5 : barWidth, // Espaçamento pequeno
        barHeight,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SpectrogramPainter oldDelegate) {
    return oldDelegate.magnitudes != magnitudes ||
           oldDelegate.baseColor != baseColor;
  }
}

class SpectrogramView extends StatelessWidget {
  final List<double> magnitudes;
  final Color color;
  final double height;
  final double width;

  const SpectrogramView({
    Key? key,
    required this.magnitudes,
    this.color = Colors.cyanAccent,
    this.height = 100,
    this.width = double.infinity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(8.0),
      child: magnitudes.isEmpty 
          ? const Center(child: Text("Sem dados espectrais", style: TextStyle(color: Colors.white54)))
          : CustomPaint(
              painter: SpectrogramPainter(
                magnitudes: magnitudes,
                baseColor: color,
              ),
              size: Size(width, height),
            ),
    );
  }
}
