import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'splash_timings.dart';

class SplashBurstPainter extends CustomPainter {
  const SplashBurstPainter(this.time);

  final double time;
  static const _destinations = [
    Offset(-120, -90),
    Offset(130, -70),
    Offset(-140, 40),
    Offset(120, 90),
    Offset(-30, -140),
    Offset(40, 130),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var i = 0; i < SplashTimings.ringStarts.length; i++) {
      final start = SplashTimings.ringStarts[i];
      if (time * SplashTimings.intro.inMilliseconds < start) continue;
      final p = SplashTimings.interval(time, start, SplashTimings.ringDuration);
      if (p >= 1) continue;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.scale(.6 + 2.8 * p);
      canvas.drawCircle(
        Offset.zero,
        75,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == 0 ? 3 : 2
          ..color = (i == 0 ? SplashColors.teal : SplashColors.coral)
              .withValues(alpha: .9 * (1 - p)),
      );
      canvas.restore();
    }
    if (time * SplashTimings.intro.inMilliseconds < SplashTimings.burstStart) {
      return;
    }
    final p = SplashTimings.interval(
      time,
      SplashTimings.burstStart,
      SplashTimings.burstDuration,
    );
    if (p >= 1) return;
    final origin = Offset(size.width / 2, size.height * .48);
    for (final destination in _destinations) {
      final position = origin + destination * p;
      final radius = 7 * (.4 + .6 * p);
      final paint = Paint()
        ..shader = ui.Gradient.radial(
          position + Offset(-.3 * radius, -.4 * radius),
          radius * 1.4,
          [
            SplashColors.goldLight.withValues(alpha: 1 - p),
            SplashColors.gold.withValues(alpha: 1 - p),
          ],
        );
      canvas.drawCircle(position, radius, paint);
    }
  }

  @override
  bool shouldRepaint(SplashBurstPainter oldDelegate) =>
      oldDelegate.time != time;
}
