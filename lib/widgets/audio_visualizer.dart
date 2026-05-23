import 'dart:math';
import 'package:flutter/material.dart';

class AudioVisualizer extends StatefulWidget {
  final bool isPlaying;
  final Color color;

  const AudioVisualizer({
    super.key,
    required this.isPlaying,
    this.color = const Color(0xFF4FC3F7),
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _controller.repeat();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      // Dejar que termine la animación suavemente
      _controller.animateTo(0, duration: const Duration(milliseconds: 500));
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
          painter: _WavePainter(
            animationValue: _controller.value,
            isPlaying: widget.isPlaying,
            color: widget.color,
          ),
          child: Container(),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  final bool isPlaying;
  final Color color;

  _WavePainter({
    required this.animationValue,
    required this.isPlaying,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isPlaying && animationValue == 0) return;

    final paint = Paint()
      ..color = color.withOpacity(0.4 * (isPlaying ? 1.0 : animationValue))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final paintGlow = Paint()
      ..color = color.withOpacity(0.2 * (isPlaying ? 1.0 : animationValue))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    // Dibujamos 3 ondas superpuestas
    _drawWave(canvas, size, paintGlow, 1.0, 0.0);
    _drawWave(canvas, size, paint, 1.0, 0.0);
    
    paint.color = color.withOpacity(0.25 * (isPlaying ? 1.0 : animationValue));
    _drawWave(canvas, size, paint, 1.5, pi / 3);
    
    paint.color = color.withOpacity(0.15 * (isPlaying ? 1.0 : animationValue));
    _drawWave(canvas, size, paint, 0.8, pi / 1.5);
  }

  void _drawWave(Canvas canvas, Size size, Paint paint, double frequency, double phaseOffset) {
    final path = Path();
    final width = size.width;
    final height = size.height;
    final mid = height / 2;

    // Amplitud base, si no está jugando se reduce
    final maxAmplitude = height * 0.4;
    final amplitude = isPlaying ? maxAmplitude : maxAmplitude * animationValue;

    path.moveTo(0, mid);

    for (double x = 0; x <= width; x += 2) {
      // Calculamos la altura de la onda usando seno
      // La animación hace que se mueva horizontalmente
      final normalizedX = x / width;
      final wavePhase = animationValue * 2 * pi * -2; // Velocidad
      final y = mid + sin((normalizedX * pi * 2 * frequency) + wavePhase + phaseOffset) * amplitude;
      
      // Hacemos que los bordes izquierdo y derecho se atenúen
      final edgeFade = sin(normalizedX * pi);
      final finalY = mid + (y - mid) * edgeFade;

      path.lineTo(x, finalY);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isPlaying != isPlaying;
  }
}
