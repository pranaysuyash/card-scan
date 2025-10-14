import 'dart:ui';
import 'package:flutter/material.dart';
import '../quantum_theme.dart';

/// Glass morphism container with neural aesthetic
class NeuralGlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double? width;
  final double? height;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final Border? border;
  final double blur;
  final Color? backgroundColor;

  const NeuralGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 40,
    this.width,
    this.height,
    this.boxShadow,
    this.gradient,
    this.border,
    this.blur = 40,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ?? QuantumTheme.cardShadow(),
        border: border ?? Border.all(
          color: QuantumTheme.glassBorder,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: gradient,
              color: backgroundColor ?? QuantumTheme.glassBase,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Morphing blob background element
class MorphingBlob extends StatefulWidget {
  final double size;
  final Color color;
  final Alignment alignment;
  final Duration duration;

  const MorphingBlob({
    super.key,
    required this.size,
    required this.color,
    this.alignment = Alignment.center,
    this.duration = const Duration(seconds: 8),
  });

  @override
  State<MorphingBlob> createState() => _MorphingBlobState();
}

class _MorphingBlobState extends State<MorphingBlob>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: widget.alignment,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.elliptical(
                    widget.size * (0.6 + 0.1 * _controller.value),
                    widget.size * (0.4 + 0.1 * (1 - _controller.value)),
                  ),
                  topRight: Radius.elliptical(
                    widget.size * (0.4 + 0.1 * (1 - _controller.value)),
                    widget.size * (0.3 + 0.1 * _controller.value),
                  ),
                  bottomLeft: Radius.elliptical(
                    widget.size * (0.3 + 0.1 * _controller.value),
                    widget.size * (0.7 + 0.1 * (1 - _controller.value)),
                  ),
                  bottomRight: Radius.elliptical(
                    widget.size * (0.7 + 0.1 * (1 - _controller.value)),
                    widget.size * (0.4 + 0.1 * _controller.value),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Holographic shimmer effect
class HolographicShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const HolographicShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 10),
  });

  @override
  State<HolographicShimmer> createState() => _HolographicShimmerState();
}

class _HolographicShimmerState extends State<HolographicShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
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
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 + 2 * _controller.value, -1),
              end: Alignment(1 + 2 * _controller.value, 1),
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.1),
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

/// Neural scan grid overlay
class NeuralScanGrid extends StatelessWidget {
  final bool isActive;
  final double gridSize;
  final Color? color;

  const NeuralScanGrid({
    super.key,
    this.isActive = false,
    this.gridSize = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isActive ? 0.5 : 0.0,
      child: CustomPaint(
        painter: _GridPainter(
          gridSize: gridSize,
          color: color ?? QuantumTheme.primaryBlue.withOpacity(0.1),
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double gridSize;
  final Color color;

  _GridPainter({
    required this.gridSize,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    // Vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
