import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:punchy_app/core/api/api_client.dart';
import 'package:punchy_app/features/customer/explore_screen.dart';
import 'package:punchy_app/features/customer/explore_business_detail_screen.dart';
import 'package:punchy_app/features/customer/explore/explore_tile.dart';
import 'package:punchy_app/features/customer/explore/explore_style.dart';

const businesses = [
  {
    'id': 'one',
    'name': 'Morning Cafe',
    'category': 'Cafe & Bakery',
    'loyaltyCards': [
      {
        'id': 'card-one',
        'punchesRequired': 5,
        'currency': 'PKR',
        'pricePerPunch': 600,
      },
    ],
  },
  {
    'id': 'two',
    'name': 'A long salon name for checking small phone layouts',
    'category': 'Salon',
    'loyaltyCards': [
      {'id': 'card-two', 'punchesRequired': 100},
    ],
  },
];

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1500));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({'token': 'test-token'});
  });
  testWidgets(
    'live search, categories, scope, empty state and banner dismissal',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final requests = <Uri>[];
      final api = ApiClient(
        baseUrl: 'https://filter.example.test',
        tokenStore: const SharedPreferencesTokenStore(),
        client: MockClient((request) async {
          requests.add(request.url);
          dynamic data = {'unreadCount': 0};
          if (request.url.path == '/customer/cards') data = [];
          if (request.url.path == '/customer/explore') {
            final category = request.url.queryParameters['category'] ?? '';
            final query = request.url.queryParameters['search'] ?? '';
            data = {
              'locationAvailable': false,
              'businesses': businesses
                  .where(
                    (b) =>
                        (category.isEmpty ||
                            b['category'].toString().contains(category)) &&
                        matchesExploreSearch(b, query),
                  )
                  .toList(),
            };
          }
          return http.Response(jsonEncode(data), 200);
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ExploreScreen(apiClient: api, positionLoader: () async => null),
        ),
      );
      await settle(tester);
      expect(find.byType(ExploreTile), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Dismiss location notice'));
      await tester.pump();
      expect(find.byTooltip('Dismiss location notice'), findsNothing);
      await tester.tap(find.byTooltip('Search businesses'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'bakery');
      await settle(tester);
      expect(find.byType(ExploreTile), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'nothing matches');
      await settle(tester);
      expect(find.byType(ExploreEmptyState), findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await settle(tester);
      await tester.tap(find.text('Salon'));
      await settle(tester);
      expect(find.byType(ExploreTile), findsOneWidget);
      expect(
        requests
            .lastWhere((u) => u.path == '/customer/explore')
            .queryParameters['category'],
        'Salon',
      );
      await tester.tap(find.text('In Your Country'));
      await settle(tester);
      expect(
        requests
            .lastWhere((u) => u.path == '/customer/explore')
            .queryParameters['scope'],
        'country',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'join uses existing endpoint once, updates CTA and tile, reverses on back',
    (tester) async {
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var joined = false;
      var joinCalls = 0;
      final joinResult = Completer<http.Response>();
      final api = ApiClient(
        baseUrl: 'https://join.example.test',
        tokenStore: const SharedPreferencesTokenStore(),
        client: MockClient((request) async {
          if (request.method == 'POST') {
            joinCalls++;
            expect(jsonDecode(request.body), {'cardId': 'card-one'});
            return joinResult.future;
          }
          dynamic data = {'unreadCount': 0};
          if (request.url.path == '/customer/cards') {
            data = joined
                ? [
                    {'cardId': 'card-one', 'punchCount': 0},
                  ]
                : [];
          }
          if (request.url.path == '/customer/explore') {
            data = {
              'locationAvailable': true,
              'businesses': [businesses.first],
            };
          }
          return http.Response(jsonEncode(data), 200);
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ExploreScreen(apiClient: api, positionLoader: () async => null),
        ),
      );
      await settle(tester);
      await tester.tap(find.byType(ExploreTile));
      await settle(tester);
      expect(find.byType(ExploreBusinessDetailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('JOIN CARD'));
      await tester.pump();
      await tester.tap(find.text('JOINING…'));
      expect(joinCalls, 1);
      joined = true;
      joinResult.complete(
        http.Response(
          jsonEncode({
            'customerCard': {'cardId': 'card-one', 'punchCount': 0},
            'message': 'Added',
          }),
          201,
        ),
      );
      await settle(tester);
      expect(find.text('CARD ADDED'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 275));
      expect(find.byType(ExploreBusinessDetailScreen), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byType(ExploreBusinessDetailScreen), findsNothing);
      expect(find.text('ADDED'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'joined progress and long detail fit a small phone; no invented price',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: ExploreBusinessDetailScreen(
            business: businesses.last,
            card: exploreCard(businesses.last),
            customerCard: const {'punchCount': 37},
            color: exploreTints[1],
            onJoin: () async => false,
          ),
        ),
      );
      await settle(tester);
      expect(find.text('YOUR CARD · 37 / 100'), findsOneWidget);
      expect(find.text('CARD ADDED'), findsOneWidget);
      expect(find.text('Not set'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
