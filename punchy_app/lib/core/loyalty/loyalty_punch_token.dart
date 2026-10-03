import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'card_palette.dart';

class LoyaltyPunchToken extends StatelessWidget {
  const LoyaltyPunchToken({
    super.key,
    required this.palette,
    required this.size,
    required this.filled,
    this.reward = false,
    this.number,
  });
  final CardPalette palette;
  final double size;
  final bool filled, reward;
  final int? number;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${number == null ? 'Punch' : 'Punch $number'}, ${filled
            ? 'collected'
            : reward
            ? 'reward'
            : 'remaining'}',
    child: ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? palette.tokenFill : null,
          ),
          child: filled
              ? Icon(
                  Icons.check_rounded,
                  color: palette.tokenCheck,
                  size: size * .5,
                )
              : CustomPaint(
                  painter: _DashedToken(palette.emptyToken),
                  child: reward
                      ? Icon(
                          Icons.card_giftcard_rounded,
                          color: palette.text,
                          size: size * .44,
                        )
                      : number == null
                      ? null
                      : Center(
                          child: Text(
                            '$number',
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              color: palette.text,
                              fontSize: size * .35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                ),
        ),
      ),
    ),
  );
}

class _DashedToken extends CustomPainter {
  const _DashedToken(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.min(1.8, size.width / 10);
    final rect = (Offset.zero & size).deflate(paint.strokeWidth);
    for (var i = 0; i < 12; i++) {
      canvas.drawArc(rect, i * math.pi / 6, math.pi / 9, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedToken oldDelegate) => color != oldDelegate.color;
}
