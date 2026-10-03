import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:punchy_app/core/api/api_client.dart';
import 'package:punchy_app/core/loyalty/card_color.dart';
import 'package:punchy_app/core/loyalty/loyalty_card_surface.dart';
import 'package:punchy_app/features/business/create_card_screen.dart';
import 'package:punchy_app/features/customer/explore/explore_style.dart';
import 'package:punchy_app/features/customer/explore/explore_tile.dart';
import 'package:punchy_app/features/customer/explore_business_detail_screen.dart';
import 'package:punchy_app/features/customer/card_detail_screen.dart';
import 'package:punchy_app/features/customer/widgets/loyalty_card_deck.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({'token': 'test'});
  });

  testWidgets('editing persists uppercase custom color and existing metadata', (
    tester,
  ) async {
    Map<String, dynamic>? saved;
    final api = ApiClient(
      tokenStore: const SharedPreferencesTokenStore(),
      client: MockClient((request) async {
        if (request.method == 'PUT') {
          expect(request.url.path, '/api/business/cards/test-card');
          saved = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{}', 200);
        }
        return http.Response(
          jsonEncode({
            'business': {'countryCode': 'PK', 'currencyCode': 'PKR'},
          }),
          200,
        );
      }),
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/edit'),
              child: const Text('Edit'),
            ),
          ),
        ),
        GoRoute(
          path: '/edit',
          builder: (_, state) => CreateCardScreen(
            apiClient: api,
            cardId: 'test-card',
            initialData: const {
              'title': 'Original title',
              'rewardDescription': 'Original reward',
              'punchesRequired': 7,
              'pricePerPunch': 250,
              'currency': 'PKR',
              'visualStyle': {
                'primaryColor': '#123456',
                'theme': 'old-theme',
                'icon': '★',
                'bgColor': '#FFFFFF',
              },
            },
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<LoyaltyCardSurface>(find.byType(LoyaltyCardSurface).first)
          .palette
          .base,
      CardColor.parse('#123456'),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('card_color_custom')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('card_color_custom')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('card_color_hex')), 'e2503a');
    await tester.ensureVisible(find.text('Use this color'));
    await tester.tap(find.text('Use this color'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Save Changes'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();
    expect(saved?['visualStyle'], {
      'primaryColor': '#E2503A',
      'theme': 'old-theme',
      'icon': '★',
      'bgColor': '#FFFFFF',
    });
    expect(saved?['punchesRequired'], 7);
    expect(saved?['rewardDescription'], 'Original reward');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'deck layers and refreshed data use own colors at large text in RTL',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Future<void> render(String firstColor) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 800),
                textScaler: TextScaler.linear(2),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: LoyaltyCardDeck(
                    cards: [
                      for (final color in [firstColor, '#000000', 'purple'])
                        {
                          'id': color,
                          'punchCount': 3,
                          'card': {
                            'punchesRequired': 100,
                            'visualStyle': {
                              'primaryColor': color == 'purple' ? null : color,
                              'theme': color,
                            },
                            'business': {
                              'name': 'A long business name',
                              'category': 'Cafe & Bakery',
                            },
                          },
                        },
                    ],
                    cardHeight: 440,
                    onOpen: (_) {},
                    onLongPress: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await render('#FFFFFF');
      final colors = tester
          .widgetList<LoyaltyCardSurface>(find.byType(LoyaltyCardSurface))
          .map((w) => CardColor.format(w.palette.base));
      expect(colors, containsAll(['#FFFFFF', '#000000', '#8B7FF5']));
      expect(tester.takeException(), isNull);
      await render('#E2503A');
      expect(
        tester
            .widgetList<LoyaltyCardSurface>(find.byType(LoyaltyCardSurface))
            .map((w) => CardColor.format(w.palette.base)),
        contains('#E2503A'),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Explore tile and detail use card color with large text and RTL',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final card = {
        'punchesRequired': 100,
        'pricePerPunch': 1234,
        'currency': 'PKR',
        'visualStyle': {'primaryColor': '#FFFFFF'},
      };
      final business = {
        'name': 'A long business name',
        'category': 'Cafe & Bakery',
        'loyaltyCards': [card],
      };
      expect(exploreCardColor(business, 1), Colors.white);
      expect(exploreCardColor({'loyaltyCards': []}, 1), exploreTints[1]);
      Widget wrap(Widget child) => MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(2),
          ),
          child: Directionality(textDirection: TextDirection.rtl, child: child),
        ),
      );
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: SizedBox(
              height: 384,
              child: ExploreTile(
                business: business,
                color: exploreCardColor(business, 0),
                added: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        wrap(
          ExploreBusinessDetailScreen(
            business: business,
            card: card,
            color: exploreTints[0],
            onJoin: () async => true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<LoyaltyCardSurface>(find.byType(LoyaltyCardSurface).first)
            .palette
            .base,
        Colors.white,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('wallet detail uses legacy palette and fits large text in RTL', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(2),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: CardDetailScreen(
              cardData: {
                'punchCount': 3,
                'card': {
                  'punchesRequired': 20,
                  'rewardDescription': 'A long reward description',
                  'validUntil': '2027-10-03',
                  'visualStyle': {'theme': 'gold'},
                  'business': {
                    'name': 'A long business name',
                    'category': 'Cafe & Bakery',
                  },
                },
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<LoyaltyCardSurface>(find.byType(LoyaltyCardSurface))
          .palette
          .base,
      CardColor.parse('gold'),
    );
  });
}
