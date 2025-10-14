import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Confetti particle for celebration animations
class ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  double gravity;
  double size;
  double hue;
  int life;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.gravity,
    required this.size,
    required this.hue,
    required this.life,
  });

  void update() {
    vy += gravity;
    x += vx;
    y += vy;
    life--;
  }

  bool get isAlive => life > 0;
}

/// Confetti animation widget for celebration micro-interactions
class ConfettiAnimation extends StatefulWidget {
  final int burstCount;
  final Duration duration;
  final VoidCallback? onComplete;

  const ConfettiAnimation({
    super.key,
    this.burstCount = 60,
    this.duration = const Duration(seconds: 3),
    this.onComplete,
  });

  @override
  State<ConfettiAnimation> createState() => _ConfettiAnimationState();
}

class _ConfettiAnimationState extends State<ConfettiAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<ConfettiParticle> _confetti = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initConfetti();
    
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete?.call();
        }
      });
    
    _controller.repeat();
  }

  void _initConfetti() {
    _confetti = List.generate(widget.burstCount, (_) {
      final centerX = 0.5;
      final centerY = 0.4;
      
      return ConfettiParticle(
        x: centerX + (_random.nextDouble() - 0.5) * 0.12,
        y: centerY + (_random.nextDouble() - 0.5) * 0.06,
        vx: (_random.nextDouble() - 0.5) * 0.006,
        vy: _random.nextDouble() * -0.006 - 0.002,
        gravity: 0.00018 + _random.nextDouble() * 0.00008,
        size: 3 + _random.nextDouble() * 4,
        hue: 160 + _random.nextDouble() * 200,
        life: 90 + _random.nextInt(30),
      );
    });
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
          painter: _ConfettiPainter(confetti: _confetti),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> confetti;

  _ConfettiPainter({required this.confetti});

  @override
  void paint(Canvas canvas, Size size) {
    // Update and draw confetti
    confetti.removeWhere((particle) => !particle.isAlive || particle.y > 1.2);
    
    for (final particle in confetti) {
      particle.update();
      
      final paint = Paint()
        ..color = HSLColor.fromAHSL(
          1.0,
          particle.hue,
          0.8,
          0.6,
        ).toColor();
      
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(particle.x * size.width, particle.y * size.height),
          width: particle.size,
          height: particle.size * 0.6,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Trigger confetti burst from anywhere
class ConfettiBurst {
  static OverlayEntry? _overlayEntry;

  static void celebrate(BuildContext context, {
    int burstCount = 60,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Remove any existing confetti
    dismiss();

    _overlayEntry = OverlayEntry(
      builder: (context) => IgnorePointer(
        child: ConfettiAnimation(
          burstCount: burstCount,
          duration: duration,
          onComplete: dismiss,
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  static void dismiss() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
