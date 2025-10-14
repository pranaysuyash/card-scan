import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Particle system for quantum neural background effects
class ParticleSystem extends StatefulWidget {
  final int particleCount;
  final Color? particleColor;
  final double maxVelocity;
  final double maxSize;
  final double connectionDistance;

  const ParticleSystem({
    super.key,
    this.particleCount = 100,
    this.particleColor,
    this.maxVelocity = 0.5,
    this.maxSize = 2.5,
    this.connectionDistance = 100,
  });

  @override
  State<ParticleSystem> createState() => _ParticleSystemState();
}

class _ParticleSystemState extends State<ParticleSystem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> _particles;
  Offset _mousePosition = Offset.zero;
  late Size _screenSize;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(
      widget.particleCount,
      (_) => Particle.random(
        maxVelocity: widget.maxVelocity,
        maxSize: widget.maxSize,
      ),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..repeat();

    // Start animation after next frame to avoid jank
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateMousePosition(PointerEvent event) {
    setState(() {
      _mousePosition = event.localPosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: _updateMousePosition,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: ParticlePainter(
              particles: _particles,
              mousePosition: _mousePosition,
              connectionDistance: widget.connectionDistance,
              particleColor: widget.particleColor,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double opacity;
  double hue;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.opacity,
    required this.hue,
  });

  factory Particle.random({
    required double maxVelocity,
    required double maxSize,
  }) {
    final random = math.Random();
    return Particle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      vx: (random.nextDouble() - 0.5) * maxVelocity,
      vy: (random.nextDouble() - 0.5) * maxVelocity,
      size: random.nextDouble() * maxSize + 0.5,
      opacity: random.nextDouble() * 0.5 + 0.2,
      hue: random.nextDouble() * 60 + 200, // Blue to purple range
    );
  }

  void update(Size size, Offset mousePosition) {
    // Update position
    x += vx / size.width;
    y += vy / size.height;

    // Wrap around edges
    if (x < 0) x = 1;
    if (x > 1) x = 0;
    if (y < 0) y = 1;
    if (y > 1) y = 0;

    // Mouse attraction
    final particlePos = Offset(x * size.width, y * size.height);
    final distance = (mousePosition - particlePos).distance;

    if (distance < 200 && distance > 0) {
      final dx = (mousePosition.dx - particlePos.dx) / distance;
      final dy = (mousePosition.dy - particlePos.dy) / distance;
      vx += dx * 0.00002;
      vy += dy * 0.00002;
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Offset mousePosition;
  final double connectionDistance;
  final Color? particleColor;

  ParticlePainter({
    required this.particles,
    required this.mousePosition,
    required this.connectionDistance,
    this.particleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    // Draw connections first (lower z-index)
    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final dx = particles[i].x - particles[j].x;
        final dy = particles[i].y - particles[j].y;
        final distance = math.sqrt(dx * dx + dy * dy);

        if (distance < connectionDistance) {
          final opacity = (1.0 - distance / connectionDistance) * 0.15;
          paint
            ..color = particleColor?.withOpacity(opacity) ??
                const Color(0xFF667eea).withOpacity(opacity)
            ..strokeWidth = 0.5;
          canvas.drawLine(
            Offset(particles[i].x * size.width, particles[i].y * size.height),
            Offset(particles[j].x * size.width, particles[j].y * size.height),
            paint,
          );
        }
      }
    }

    // Draw particles
    for (final particle in particles) {
      particle.update(size, mousePosition);

      final distanceToMouse = math.sqrt(
        math.pow(particle.x * size.width - mousePosition.dx, 2) +
            math.pow(particle.y * size.height - mousePosition.dy, 2),
      );

      final adjustedSize = particle.size *
          (1.0 + (100.0 / (distanceToMouse + 100.0)));

      paint
        ..color = particleColor?.withOpacity(particle.opacity) ??
            HSLColor.fromAHSL(
              particle.opacity,
              particle.hue,
              0.8,
              0.6,
            ).toColor()
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        adjustedSize,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
