import 'package:flutter/material.dart';

abstract final class SplashTimings {
  static const intro = Duration(milliseconds: 2100);
  static const reducedIntro = Duration(milliseconds: 300);
  static const exit = Duration(milliseconds: 250);
  static const loadingThreshold = Duration(seconds: 6);
  static const loadingFade = Duration(milliseconds: 600);
  static const ease = Cubic(.2, .8, .2, 1);

  static const slamStart = 150;
  static const slamDuration = 700;
  static const shakeStart = 720;
  static const shakeDuration = 350;
  static const ringStarts = [720, 820];
  static const ringDuration = 800;
  static const burstStart = 720;
  static const burstDuration = 900;
  static const wordStart = 1000;
  static const letterStagger = 60;
  static const letterDuration = 550;
  static const tagStart = 1500;
  static const tagDuration = 600;

  static double interval(
    double time,
    int start,
    int duration, {
    Curve curve = ease,
  }) => Interval(
    start / intro.inMilliseconds,
    (start + duration) / intro.inMilliseconds,
    curve: curve,
  ).transform(time.clamp(0.0, 1.0));
}

abstract final class SplashColors {
  static const teal = Color(0xFF14A892);
  static const coral = Color(0xFFF26B52);
  static const ink = Color(0xFF14201F);
  static const muted = Color(0xFF4F5B5A);
  static const goldLight = Color(0xFFF6D27A);
  static const gold = Color(0xFFD9A441);
}
