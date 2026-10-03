import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:punchy_app/core/loyalty/card_color.dart';
import 'package:punchy_app/core/loyalty/card_palette.dart';

void main() {
  test('hex input and storage format are opaque uppercase RGB', () {
    expect(CardColor.parseHex(' e2503a '), '#E2503A');
    expect(CardColor.parseHex('#aBcDeF'), '#ABCDEF');
    expect(CardColor.format(const Color(0x44ABCDEF)), '#ABCDEF');
    expect(CardColor.parse('#FFFFFF'), Colors.white);
    for (final value in ['', '#FFF', '#FFFFFFFF', '#GGGGGG', 'red']) {
      expect(CardColor.parseHex(value), isNull);
    }
  });

  test(
    'all original theme names and indices use the Create Card swatch colors',
    () {
      const expected = ['#FF8368', '#14B8A6', '#8B7FF5', '#FFC658'];
      for (var i = 0; i < expected.length; i++) {
        expect(
          CardColor.normalize(CardColor.presets.keys.elementAt(i)),
          expected[i],
        );
        expect(CardColor.normalize(i), expected[i]);
        expect(CardColor.normalize('$i'), expected[i]);
      }
    },
  );

  test('malformed or missing card styles fall back and canonical hex wins', () {
    for (final value in [
      null,
      true,
      -1,
      99,
      1.5,
      [],
      {},
      'unknown',
      '#BADHEX',
    ]) {
      expect(CardColor.normalize(value), CardColor.defaultHex);
    }
    for (final card in [
      null,
      {},
      {'visualStyle': []},
      {
        'visualStyle': {'primaryColor': '#BADHEX'},
      },
    ]) {
      expect(CardColor.format(CardColor.fromCard(card)), CardColor.defaultHex);
    }
    expect(
      CardColor.format(
        CardColor.fromCard({
          'card': {
            'visualStyle': {'primaryColor': '#e2503a', 'theme': 'teal'},
          },
        }),
      ),
      '#E2503A',
    );
    expect(
      CardColor.format(
        CardColor.fromCard({
          'visualStyle': {'theme': 2},
        }),
      ),
      '#8B7FF5',
    );
  });

  for (final hex in [
    '#FFFFFF',
    '#000000',
    '#F5B14C',
    '#0B6B63',
    '#E2503A',
    '#7C5CE0',
    '#7E7E7E',
  ]) {
    test(
      '$hex has readable primary/secondary text across the whole gradient',
      () {
        final color = CardColor.parse(hex);
        final palette = CardPalette.fromColor(color);
        expect([Colors.white, CardPalette.ink], contains(palette.text));
        for (var i = 0; i <= 20; i++) {
          final background = Color.lerp(palette.start, palette.end, i / 20)!;
          expect(
            CardPalette.contrast(palette.text, background),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            CardPalette.contrast(palette.secondaryText, background),
            greaterThanOrEqualTo(4.5),
          );
        }
        expect(identical(palette, CardPalette.fromColor(color)), isTrue);
        expect(palette.tokenCheck, color);
        expect(palette.border.a, greaterThan(0));
      },
    );
  }
  test('white cards choose ink; black cards choose white', () {
    expect(CardPalette.fromColor(Colors.white).text, CardPalette.ink);
    expect(CardPalette.fromColor(Colors.black).text, Colors.white);
  });
}
