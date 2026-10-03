import 'package:flutter/material.dart';

class ColorPickerSquare extends StatelessWidget {
  const ColorPickerSquare({
    super.key,
    required this.color,
    required this.onChanged,
  });
  final HSVColor color;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Saturation and brightness',
    value:
        '${(color.saturation * 100).round()}% saturation, ${(color.value * 100).round()}% brightness',
    increasedValue:
        '${((color.saturation + .05).clamp(0, 1) * 100).round()}% saturation, ${(color.value * 100).round()}% brightness',
    decreasedValue:
        '${((color.saturation - .05).clamp(0, 1) * 100).round()}% saturation, ${(color.value * 100).round()}% brightness',
    onIncrease: () =>
        onChanged(color.withSaturation((color.saturation + .05).clamp(0, 1))),
    onDecrease: () =>
        onChanged(color.withSaturation((color.saturation - .05).clamp(0, 1))),
    child: LayoutBuilder(
      builder: (_, constraints) {
        const height = 180.0;
        void select(Offset position) => onChanged(
          color
              .withSaturation((position.dx / constraints.maxWidth).clamp(0, 1))
              .withValue((1 - position.dy / height).clamp(0, 1)),
        );
        return GestureDetector(
          key: const Key('color_saturation_brightness'),
          onPanDown: (details) => select(details.localPosition),
          onPanUpdate: (details) => select(details.localPosition),
          child: RepaintBoundary(
            child: CustomPaint(
              size: Size(constraints.maxWidth, height),
              painter: _SquarePainter(color),
            ),
          ),
        );
      },
    ),
  );
}

class _SquarePainter extends CustomPainter {
  const _SquarePainter(this.color);
  final HSVColor color;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)));
    canvas.drawRect(
      rect,
      Paint()..color = HSVColor.fromAHSV(1, color.hue, 1, 1).toColor(),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Colors.white, Colors.transparent],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(rect),
    );
    canvas.restore();
    final point = Offset(
      (color.saturation * size.width).clamp(7, size.width - 7),
      ((1 - color.value) * size.height).clamp(7, size.height - 7),
    );
    canvas.drawCircle(
      point,
      7,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawCircle(
      point,
      7,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_SquarePainter oldDelegate) => oldDelegate.color != color;
}
