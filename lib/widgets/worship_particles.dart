import 'dart:math';
import 'package:flutter/material.dart';

class WorshipParticles extends StatefulWidget {
  final bool isMinor;

  const WorshipParticles({super.key, required this.isMinor});

  @override
  State<WorshipParticles> createState() => _WorshipParticlesState();
}

class _WorshipParticlesState extends State<WorshipParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    for (int i = 0; i < 100; i++) {
      _particles.add(Particle.random());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usamos el mismo color para ambas pestañas
    final particleColor = Colors.blue.shade300;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(_particles, _controller.value, particleColor),
          child: const SizedBox.expand(), // Asegura que ocupe toda la pantalla
        );
      },
    );
  }
}

class Particle {
  Offset position;
  double radius;
  double speed;
  double direction;

  Particle({
    required this.position,
    required this.radius,
    required this.speed,
    required this.direction,
  });

  factory Particle.random() {
    final random = Random();
    return Particle(
      position: Offset(random.nextDouble(), random.nextDouble()),
      radius: random.nextDouble() * 2 + 1,
      speed: random.nextDouble() * 0.001,
      direction: random.nextDouble() * 2 * pi,
    );
  }

  void update(double deltaTime) {
    final dx = cos(direction) * speed;
    final dy = sin(direction) * speed;
    position += Offset(dx, dy);
    if (position.dx < 0 || position.dx > 1 || position.dy < 0 || position.dy > 1) {
      position = Offset(Random().nextDouble(), Random().nextDouble());
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final Color color;

  ParticlePainter(this.particles, this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.1);

    for (var p in particles) {
      p.update(progress);
      final offset = Offset(p.position.dx * size.width, p.position.dy * size.height);
      canvas.drawCircle(offset, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}

