import 'package:flutter/material.dart';

import '../../../core/loyalty/card_color.dart';
import '../../../core/loyalty/card_palette.dart';
import 'card_color_picker_sheet.dart';

class CardColorSwatches extends StatefulWidget {
  const CardColorSwatches({
    super.key,
    required this.color,
    required this.onChanged,
    required this.cardTitle,
  });
  final Color color;
  final ValueChanged<Color> onChanged;
  final String cardTitle;
  @override
  State<CardColorSwatches> createState() => _CardColorSwatchesState();
}

class _CardColorSwatchesState extends State<CardColorSwatches> {
  late bool _custom = !CardColor.presets.containsValue(
    CardColor.format(widget.color),
  );

  Future<void> _openCustom() async {
    final previous = widget.color;
    final wasCustom = _custom;
    final picked = await showModalBottomSheet<Color>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => CardColorPickerSheet(
        initialColor: previous,
        title: widget.cardTitle,
        onPreview: (color) {
          if (!mounted) return;
          setState(() => _custom = true);
          widget.onChanged(color);
        },
      ),
    );
    if (!mounted) return;
    setState(() => _custom = picked == null ? wasCustom : true);
    widget.onChanged(picked ?? previous);
  }

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 8,
    children: [
      for (final preset in CardColor.presets.entries)
        _swatch(
          label: '${preset.key[0].toUpperCase()}${preset.key.substring(1)}',
          color: CardColor.parse(preset.value),
          selected: !_custom && CardColor.format(widget.color) == preset.value,
          onTap: () {
            setState(() => _custom = false);
            widget.onChanged(CardColor.parse(preset.value));
          },
        ),
      _swatch(
        label: 'Custom',
        color: widget.color,
        selected: _custom,
        rainbow: true,
        onTap: _openCustom,
      ),
    ],
  );

  Widget _swatch({
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
    bool rainbow = false,
  }) => Semantics(
    label:
        '$label color${selected ? ', selected: ${CardColor.format(color)}' : ''}',
    button: true,
    selected: selected,
    child: ExcludeSemantics(
      child: InkWell(
        key: Key('card_color_${label.toLowerCase()}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? CardPalette.ink : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Container(
                  padding: EdgeInsets.all(rainbow ? 3 : 0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rainbow ? null : color,
                    gradient: rainbow
                        ? const SweepGradient(
                            colors: [
                              Colors.red,
                              Colors.yellow,
                              Colors.green,
                              Colors.cyan,
                              Colors.blue,
                              Colors.purple,
                              Colors.red,
                            ],
                          )
                        : null,
                  ),
                  child: rainbow
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? color
                                : Theme.of(context).colorScheme.surface,
                          ),
                        )
                      : null,
                ),
              ),
              if (rainbow) const Text('Custom', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    ),
  );
}
