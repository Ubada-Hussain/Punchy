import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'splash_timings.dart';

class SplashWordmark extends StatelessWidget {
  const SplashWordmark({
    super.key,
    required this.time,
    required this.reducedMotion,
  });

  final double time;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [for (var i = 0; i < 'Punchy'.length; i++) _letter(i)],
      ),
    ),
  );

  Widget _letter(int index) {
    final p = reducedMotion
        ? 1.0
        : SplashTimings.interval(
            time,
            SplashTimings.wordStart + index * SplashTimings.letterStagger,
            SplashTimings.letterDuration,
          );
    return Opacity(
      opacity: p,
      child: FractionalTranslation(
        translation: Offset(0, 1.1 * (1 - p)),
        child: Text(
          'Punchy'[index],
          style: GoogleFonts.outfit(
            fontSize: 52,
            height: 1,
            fontWeight: FontWeight.w600,
            letterSpacing: -1,
            color: SplashColors.teal,
          ),
        ),
      ),
    );
  }
}

class SplashTagline extends StatelessWidget {
  const SplashTagline({
    super.key,
    required this.time,
    required this.reducedMotion,
  });

  final double time;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: reducedMotion
        ? 1
        : SplashTimings.interval(
            time,
            SplashTimings.tagStart,
            SplashTimings.tagDuration,
            curve: const Cubic(.25, .1, .25, 1),
          ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text.rich(
        TextSpan(
          style: GoogleFonts.dmSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
            color: SplashColors.ink,
          ),
          children: const [
            TextSpan(text: 'THE ULTIMATE '),
            TextSpan(
              text: 'LOYALTY',
              style: TextStyle(color: SplashColors.teal),
            ),
            TextSpan(text: ' APP'),
          ],
        ),
      ),
    ),
  );
}
