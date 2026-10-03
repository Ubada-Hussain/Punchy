import 'package:flutter/material.dart';

import 'card_palette.dart';

/// Shared card surface: all card shapes retain a visible border and the same
/// cached palette, whether shown in a deck, wallet, preview or business list.
class LoyaltyCardSurface extends StatelessWidget {
  const LoyaltyCardSurface({
    super.key,
    required this.palette,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 22,
    this.shadow = true,
  });

  final CardPalette palette;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool shadow;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: palette.gradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: palette.border),
      boxShadow: shadow
          ? [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ]
          : null,
    ),
    child: IconTheme.merge(
      data: IconThemeData(color: palette.text),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: palette.text),
        child: Padding(padding: padding, child: child),
      ),
    ),
  );
}
