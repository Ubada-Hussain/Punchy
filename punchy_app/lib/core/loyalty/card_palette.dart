import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'card_color.dart';

class CardPalette {
  CardPalette._(this.base, this.start, this.end, this.text);

  static const ink = Color(0xFF14201F);
  static final _cache = <int, CardPalette>{};
  final Color base, start, end, text;

  factory CardPalette.fromCard(dynamic card) =>
      CardPalette.fromColor(CardColor.fromCard(card));

  factory CardPalette.fromColor(Color color) {
    final base = color.withAlpha(255);
    final key = base.toARGB32();
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      return cached;
    }
    final hsl = HSLColor.fromColor(base);
    Color shade(double lightness) =>
        hsl.withLightness(lightness.clamp(0.0, 1.0)).toColor();
    var top = shade(hsl.lightness + .06);
    var bottom = shade(hsl.lightness - .08);
    final mid = Color.lerp(top, bottom, .5)!;
    final text = contrast(Colors.white, mid) >= contrast(ink, mid)
        ? Colors.white
        : ink;
    // White and the specified ink have a small luminance gap where neither
    // reaches 4.5:1. Nudge lightness (never hue/saturation) as needed, also
    // protecting text at the gradient's lightest/darkest edge.
    var shift = 0.0;
    for (
      var i = 0;
      i < 100 && math.min(contrast(text, top), contrast(text, bottom)) < 4.5;
      i++
    ) {
      shift += text == Colors.white ? -.01 : .01;
      top = shade(hsl.lightness + .06 + shift);
      bottom = shade(hsl.lightness - .08 + shift);
    }
    final palette = CardPalette._(base, top, bottom, text);
    if (_cache.length >= 256) _cache.remove(_cache.keys.first);
    _cache[key] = palette;
    return palette;
  }

  static double contrast(Color a, Color b) {
    final la = a.computeLuminance(), lb = b.computeLuminance();
    return (math.max(la, lb) + .05) / (math.min(la, lb) + .05);
  }

  Color get secondaryText => text;
  Color get tokenFill => text;
  Color get tokenCheck => base;
  Color get emptyToken => text.withValues(alpha: .5);
  Color get border => text.withValues(alpha: .28);
  Color get overlay => text == Colors.white
      ? Colors.black.withValues(alpha: .18)
      : Colors.white.withValues(alpha: .38);
  Color get shadow => end.withValues(alpha: .25);
  LinearGradient get gradient => LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [start, end],
  );
}
