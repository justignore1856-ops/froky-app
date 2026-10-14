import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hyper_commerce/config/global.dart';

class LikeBurstEffect extends StatefulWidget {
  final Widget child;
  final bool isLiked;
  final VoidCallback onTap;

  const LikeBurstEffect({
    super.key,
    required this.child,
    required this.isLiked,
    required this.onTap,
  });

  @override
  State<LikeBurstEffect> createState() => _LikeBurstEffectState();
}

class _LikeBurstEffectState extends State<LikeBurstEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_HeartParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Slower, smooth 1.8-second upward floating animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _generateParticles();
  }

  void _generateParticles() {
    _particles.clear();
    const colors = [
      Color(0xFFFF2D55),
      Color(0xFFFF3B30),
      Color(0xFFFF5E3A),
      Color(0xFFFF2A68),
      Color(0xFFFF7597),
      Color(0xFFFF1493),
      Color(0xFFFF6B81),
      Color(0xFFFF4757),
      Color(0xFFFF3838),
    ];

    // 18 larger particles for a rich, vibrant heart shower
    for (int i = 0; i < 18; i++) {
      // Broad upward fountain angle (-90 deg ± 65 deg)
      final angle = -pi / 2 + (_random.nextDouble() - 0.5) * 2.2;
      final distance = 60.0 + _random.nextDouble() * 105.0;
      final size = 16.0 + _random.nextDouble() * 20.0; // Larger heart sizes
      final rotation = (_random.nextDouble() - 0.5) * 1.6;
      final speedFactor = 0.75 + _random.nextDouble() * 0.5; // Staggered speeds
      final color = colors[i % colors.length];

      _particles.add(
        _HeartParticle(
          angle: angle,
          distance: distance,
          size: size,
          rotation: rotation,
          speedFactor: speedFactor,
          color: color,
        ),
      );
    }
  }

  void trigger() {
    _generateParticles();
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Hello');
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        widget.onTap();
        final bool isLoggedIn =
            Global.userData != null && Global.userData!.token.isNotEmpty;
        if (isLoggedIn && !widget.isLiked) {
          trigger();
        }
      },
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Rich Floating Hearts Shower (18 larger hearts with slow, graceful float)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (!_controller.isAnimating) return const SizedBox.shrink();
              final rawProgress = _controller.value;

              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: _particles.map((particle) {
                  // Individual progression with staggered speed
                  final particleProgress =
                      (rawProgress * particle.speedFactor).clamp(0.0, 1.0);
                  final easedProgress =
                      Curves.easeOutCubic.transform(particleProgress);

                  final currentDist = particle.distance * easedProgress;
                  final dx = cos(particle.angle) * currentDist;
                  final dy = sin(particle.angle) * currentDist;

                  // Pop in quickly, stay full size, gently shrink near end
                  final scale = sin(particleProgress * pi).clamp(0.0, 1.3);
                  // Smooth fade-out in second half
                  final opacity = (1.0 - Curves.easeIn.transform(rawProgress))
                      .clamp(0.0, 1.0);

                  return Transform.translate(
                    offset: Offset(dx.w, dy.h),
                    child: Transform.rotate(
                      angle: particle.rotation * rawProgress,
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: Icon(
                            Icons.favorite_rounded,
                            color: particle.color,
                            size: particle.size.r,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // 2. Clean Main Action Heart Button (No scale distortion on child)
          widget.child,
        ],
      ),
    );
  }
}

/// Standalone larger heart burst shower for center double-tap burst
class HeartBurstShower extends StatefulWidget {
  final VoidCallback? onComplete;
  final int particleCount;
  final double baseDistance;
  final double sizeMultiplier;

  const HeartBurstShower({
    super.key,
    this.onComplete,
    this.particleCount = 24,
    this.baseDistance = 90.0,
    this.sizeMultiplier = 1.6,
  });

  @override
  State<HeartBurstShower> createState() => _HeartBurstShowerState();
}

class _HeartBurstShowerState extends State<HeartBurstShower>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_HeartParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _generateParticles();
    _controller.forward().then((_) {
      if (mounted) {
        widget.onComplete?.call();
      }
    });
  }

  void _generateParticles() {
    _particles.clear();
    const colors = [
      Color(0xFFFF2D55),
      Color(0xFFFF3B30),
      Color(0xFFFF5E3A),
      Color(0xFFFF2A68),
      Color(0xFFFF7597),
      Color(0xFFFF1493),
      Color(0xFFFF6B81),
      Color(0xFFFF4757),
      Color(0xFFFF3838),
    ];

    for (int i = 0; i < widget.particleCount; i++) {
      // 360-degree fountain burst with upward bias (-pi/2 +/- 1.4 rad)
      final angle = -pi / 2 + (_random.nextDouble() - 0.5) * 2.8;
      final distance = widget.baseDistance + _random.nextDouble() * 130.0;
      final size = (18.0 + _random.nextDouble() * 24.0) * widget.sizeMultiplier;
      final rotation = (_random.nextDouble() - 0.5) * 1.8;
      final speedFactor = 0.7 + _random.nextDouble() * 0.6;
      final color = colors[i % colors.length];

      _particles.add(
        _HeartParticle(
          angle: angle,
          distance: distance,
          size: size,
          rotation: rotation,
          speedFactor: speedFactor,
          color: color,
        ),
      );
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
      builder: (context, _) {
        final rawProgress = _controller.value;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: _particles.map((particle) {
            final particleProgress =
                (rawProgress * particle.speedFactor).clamp(0.0, 1.0);
            final easedProgress =
                Curves.easeOutCubic.transform(particleProgress);

            final currentDist = particle.distance * easedProgress;
            final dx = cos(particle.angle) * currentDist;
            final dy = sin(particle.angle) * currentDist;

            final scale = sin(particleProgress * pi).clamp(0.0, 1.4);
            final opacity =
                (1.0 - Curves.easeIn.transform(rawProgress)).clamp(0.0, 1.0);

            return Transform.translate(
              offset: Offset(dx.w, dy.h),
              child: Transform.rotate(
                angle: particle.rotation * rawProgress,
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: Icon(
                      Icons.favorite_rounded,
                      color: particle.color,
                      size: particle.size.r,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _HeartParticle {
  final double angle;
  final double distance;
  final double size;
  final double rotation;
  final double speedFactor;
  final Color color;

  _HeartParticle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.rotation,
    required this.speedFactor,
    required this.color,
  });
}
