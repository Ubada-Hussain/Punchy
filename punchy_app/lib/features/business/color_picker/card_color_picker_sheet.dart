import 'package:flutter/material.dart';

import '../../../core/loyalty/card_color.dart';
import '../../../core/loyalty/card_palette.dart';
import '../../../core/loyalty/loyalty_card_surface.dart';
import 'color_picker_square.dart';

class CardColorPickerSheet extends StatefulWidget {
  const CardColorPickerSheet({
    super.key,
    required this.initialColor,
    required this.onPreview,
    required this.title,
  });
  final Color initialColor;
  final ValueChanged<Color> onPreview;
  final String title;
  @override
  State<CardColorPickerSheet> createState() => _CardColorPickerSheetState();
}

class _CardColorPickerSheetState extends State<CardColorPickerSheet> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initialColor);
  late final _hex = TextEditingController(
    text: CardColor.format(widget.initialColor),
  );
  bool _valid = true;

  void _select(HSVColor value) {
    final color = value.toColor();
    setState(() {
      _hsv = value;
      _valid = true;
      _hex.text = CardColor.format(color);
    });
    widget.onPreview(color);
  }

  void _typeHex(String value) {
    final hex = CardColor.parseHex(value);
    setState(() {
      _valid = hex != null;
      if (hex != null) _hsv = HSVColor.fromColor(CardColor.parse(hex));
    });
    if (hex != null) widget.onPreview(CardColor.parse(hex));
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = CardPalette.fromColor(_hsv.toColor());
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Custom card color',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            LoyaltyCardSurface(
              palette: palette,
              shadow: false,
              padding: const EdgeInsets.all(16),
              radius: 16,
              child: Row(
                children: [
                  Icon(Icons.loyalty_rounded, color: palette.text),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ColorPickerSquare(color: _hsv, onChanged: _select),
            const SizedBox(height: 8),
            Text('Hue', style: Theme.of(context).textTheme.labelLarge),
            Slider(
              key: const Key('card_color_hue'),
              value: _hsv.hue,
              min: 0,
              max: 360,
              label: '${_hsv.hue.round()}°',
              semanticFormatterCallback: (value) =>
                  '${value.round()} degrees hue',
              onChanged: (value) => _select(_hsv.withHue(value)),
            ),
            TextFormField(
              key: const Key('card_color_hex'),
              controller: _hex,
              textDirection: TextDirection.ltr,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              onChanged: _typeHex,
              scrollPadding: const EdgeInsets.all(32),
              decoration: InputDecoration(
                labelText: 'Hex color',
                hintText: '#RRGGBB',
                errorText: _valid
                    ? null
                    : 'Enter 6 hex digits, for example #E2503A',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 48),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(44, 48),
                    ),
                    onPressed: _valid
                        ? () =>
                              Navigator.pop(context, CardColor.parse(_hex.text))
                        : null,
                    child: const Text(
                      'Use this color',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
