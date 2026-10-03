import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'splash_painters.dart';
import 'splash_timings.dart';

class SplashStage extends StatelessWidget {
  const SplashStage({
    super.key,
    required this.time,
    required this.reducedMotion,
  });

  final double time;
  final bool reducedMotion;

  static double _keyframe(double p, List<double> stops, List<double> values) {
    for (var i = 1; i < stops.length; i++) {
      if (p <= stops[i]) {
        final t = SplashTimings.ease.transform(
          ((p - stops[i - 1]) / (stops[i] - stops[i - 1])).clamp(0.0, 1.0),
        );
        return values[i - 1] + (values[i] - values[i - 1]) * t;
      }
    }
    return values.last;
  }

  Offset _shake() {
    final p = SplashTimings.interval(
      time,
      SplashTimings.shakeStart,
      SplashTimings.shakeDuration,
      curve: Curves.linear,
    );
    const offsets = [
      Offset.zero,
      Offset(-4, 2),
      Offset(4, -2),
      Offset(-2, 1),
      Offset(2, -1),
      Offset.zero,
    ];
    final segment = (p * 5).floor().clamp(0, 4);
    return Offset.lerp(
      offsets[segment],
      offsets[segment + 1],
      p * 5 - segment,
    )!;
  }

  @override
  Widget build(BuildContext context) {
    final p = SplashTimings.interval(
      time,
      SplashTimings.slamStart,
      SplashTimings.slamDuration,
      curve: Curves.linear,
    );
    final scale = reducedMotion
        ? 1.0
        : _keyframe(p, [0, .55, .75, 1], [2.3, .92, 1.04, 1]);
    final angle = reducedMotion
        ? 0.0
        : _keyframe(p, [0, .55, 1], [-6, 1, 0]) * math.pi / 180;
    final opacity = reducedMotion ? 1.0 : _keyframe(p, [0, .55, 1], [0, 1, 1]);
    return RepaintBoundary(
      child: Transform.translate(
        offset: reducedMotion ? Offset.zero : _shake(),
        child: SizedBox(
          width: 150,
          height: 170,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (!reducedMotion)
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: CustomPaint(painter: SplashBurstPainter(time)),
                  ),
                ),
              Positioned.fill(
                child: Opacity(
                  opacity: opacity,
                  child: Transform(
                    alignment: const Alignment(0, .2),
                    transform: Matrix4.identity()
                      ..rotateZ(angle)
                      ..scaleByDouble(scale, scale, 1, 1),
                    child: Image.asset(
                      'assets/punchy_splash_mark.png',
                      width: 150,
                      height: 170,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
