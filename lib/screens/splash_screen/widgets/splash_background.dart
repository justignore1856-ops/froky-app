import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hyper_commerce/config/theme.dart';

class SplashAnimatedBackground extends StatefulWidget {
  final Widget? child;
  final Color glowColor;

  const SplashAnimatedBackground({
    super.key,
    this.child,
    this.glowColor = AppTheme.primaryColor,
  });

  @override
  State<SplashAnimatedBackground> createState() =>
      _SplashAnimatedBackgroundState();
}

class _SplashAnimatedBackgroundState extends State<SplashAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          radius: 1.1,
          colors: [Color(0xFF1E1E1E), Color(0xFF050505), Color(0xFF000000)],
          stops: [0.0, 0.7, 1.0],
        ),
      ),
      child: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _GlowRimPainter(
                      t: _controller.value,
                      glowColor: widget.glowColor,
                    ),
                  );
                },
              ),
            ),
            if (widget.child != null) widget.child!,
          ],
        ),
      ),
    );
  }
}

class _GlowRimPainter extends CustomPainter {
  final double t;
  final Color glowColor;

  _GlowRimPainter({required this.t, required this.glowColor});

  static const double _widthFactor = 1.24;
  static const double _heightFactor = 1.02;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(
      center: center,
      width: size.width * _widthFactor,
      height: size.height * _heightFactor,
    );
    final phase = math.sin(t * 2 * math.pi);
    final intensity = 0.7 + 0.3 * (0.5 + 0.5 * phase);

    _drawCornerArc(canvas, rect, math.pi, intensity);
    _drawCornerArc(canvas, rect, 0, intensity);
  }

  void _drawCornerArc(
      Canvas canvas, Rect rect, double startAngle, double intensity) {
    const sweep = math.pi / 2;
    const clear = Color(0x00000000);
    final bright = glowColor.withValues(alpha: intensity);
    final mid = glowColor.withValues(alpha: intensity * 0.4);

    final shader = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweep,
      tileMode: TileMode.decal,
      colors: [clear, mid, bright, mid, clear],
      stops: const [0.0, 0.34, 0.5, 0.66, 1.0],
    ).createShader(rect);

    final path = Path()..addArc(rect, startAngle, sweep);

    final soft = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..shader = shader
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26);
    canvas.drawPath(path, soft);

    final coreLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = shader
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);
    canvas.drawPath(path, coreLine);
  }

  @override
  bool shouldRepaint(covariant _GlowRimPainter old) =>
      old.t != t || old.glowColor != glowColor;
}
