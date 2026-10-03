import 'package:flutter/material.dart';

class ExploreNotchClipper extends CustomClipper<Path> {
  const ExploreNotchClipper({
    this.depth = 24,
    this.start = .56,
    this.end = .64,
  });
  final double depth;
  final double start;
  final double end;
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, depth)
    ..lineTo(size.width * start, depth)
    ..lineTo(size.width * end, 0)
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height)
    ..lineTo(0, size.height)
    ..close();
  @override
  bool shouldReclip(ExploreNotchClipper old) =>
      old.depth != depth || old.start != start || old.end != end;
}
