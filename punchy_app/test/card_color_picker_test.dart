import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:punchy_app/core/loyalty/card_color.dart';
import 'package:punchy_app/core/loyalty/card_palette.dart';
import 'package:punchy_app/core/loyalty/loyalty_card_surface.dart';
import 'package:punchy_app/features/business/color_picker/card_color_swatches.dart';
import 'package:punchy_app/features/business/color_picker/card_color_picker_sheet.dart';

void main() {
  testWidgets(
    'hex input and action remain accessible above keyboard at large text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              viewInsets: EdgeInsets.only(bottom: 280),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              body: CardColorPickerSheet(
                initialColor: Colors.white,
                title: 'A long card title',
                onPreview: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.byKey(const Key('card_color_hex')));
      await tester.enterText(
        find.byKey(const Key('card_color_hex')),
        '#000000',
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Use this color'));
      expect(
        tester.getRect(find.text('Use this color')).bottom,
        lessThanOrEqualTo(360),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'preset, live hex/drag preview, invalid input and cancel preserve selection',
    (tester) async {
      var selected = CardColor.parse('teal');
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Column(
                children: [
                  LoyaltyCardSurface(
                    palette: CardPalette.fromColor(selected),
                    child: const Text('Preview'),
                  ),
                  CardColorSwatches(
                    color: selected,
                    cardTitle: 'Coffee Lovers Card',
                    onChanged: (color) => setState(() => selected = color),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('card_color_purple')));
      await tester.pumpAndSettle();
      expect(CardColor.format(selected), '#8B7FF5');
      await tester.tap(find.byKey(const Key('card_color_custom')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('card_color_hex')), 'e2503a');
      await tester.pump();
      expect(CardColor.format(selected), '#E2503A');
      expect(
        tester
            .widget<LoyaltyCardSurface>(find.byType(LoyaltyCardSurface).first)
            .palette
            .base,
        CardColor.parse('#E2503A'),
      );
      await tester.ensureVisible(find.text('Use this color'));
      await tester.tap(find.text('Use this color'));
      await tester.pumpAndSettle();
      expect(CardColor.format(selected), '#E2503A');
      await tester.tap(find.byKey(const Key('card_color_custom')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('card_color_hex')), 'FFFFFF');
      await tester.pump();
      expect(selected, Colors.white);
      await tester.drag(
        find.byKey(const Key('color_saturation_brightness')),
        const Offset(40, 20),
      );
      await tester.pump();
      expect(selected, isNot(Colors.white));
      await tester.enterText(
        find.byKey(const Key('card_color_hex')),
        'invalid',
      );
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Use this color'),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.text('Cancel'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(CardColor.format(selected), '#E2503A');
      await tester.tap(find.byKey(const Key('card_color_teal')));
      await tester.pumpAndSettle();
      expect(CardColor.format(selected), '#14B8A6');
      expect(tester.takeException(), isNull);
    },
  );
}
