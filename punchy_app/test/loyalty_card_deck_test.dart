import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:punchy_app/features/customer/widgets/loyalty_card_deck.dart';

Map<String, dynamic> card(int id, {int required = 5}) => {
  'id': '$id',
  'punchCount': 3,
  'isCompleted': false,
  'card': {
    'id': 'card$id',
    'punchesRequired': required,
    'business': {
      'id': 'business$id',
      'name': 'A very long business name with several words $id',
      'category': 'Cafe & Bakery',
    },
  },
};

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('small screens fit real programs from 1 through 100 punches', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final required in [1, 5, 7, 20, 100]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoyaltyCardDeck(
              cards: [card(1, required: required)],
              cardHeight: 440,
              onOpen: (_) {},
              onLongPress: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$required punch layout');
      expect(find.byType(PunchToken), findsNWidgets(required));
      expect(find.textContaining('Expires'), findsNothing);
    }
  });

  testWidgets('swiping synchronizes focus, opening and long press options', (
    tester,
  ) async {
    Map<String, dynamic>? opened;
    Map<String, dynamic>? held;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LoyaltyCardDeck(
            cards: [card(1), card(2), card(3)],
            cardHeight: 440,
            onOpen: (card) => opened = card,
            onLongPress: (card) => held = card,
          ),
        ),
      ),
    );
    await tester.drag(find.byType(LoyaltyCardDeck), const Offset(-240, 0));
    await tester.pumpAndSettle();
    expect(tester.widget<DeckPager>(find.byType(DeckPager)).active, 1);
    await tester.tap(find.byType(LoyaltyDeckCard).last);
    expect(opened?['id'], '2');
    await tester.longPress(find.byType(LoyaltyDeckCard).last);
    expect(held?['id'], '2');
    expect(tester.takeException(), isNull);
  });
}
