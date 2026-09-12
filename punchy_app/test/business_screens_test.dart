import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:punchy_app/core/theme/app_theme.dart';
import 'package:punchy_app/features/business/create_card_screen.dart';
import 'package:punchy_app/features/business/business_dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  group('CreateCardScreen Widget Tests', () {
    testWidgets('Renders all fields including new price setting field', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CreateCardScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Header
      expect(find.text('Create Loyalty Card'), findsOneWidget);
      expect(find.text('Set up your card and start rewarding your customers.'), findsOneWidget);

      // Live Preview Card
      expect(find.text('Coffee Lovers Card'), findsWidgets);
      expect(find.text('Live preview'), findsOneWidget);

      // Form Fields
      expect(find.text('Card name'), findsOneWidget);
      expect(find.text('Card validity (Valid till)'), findsOneWidget);
      expect(find.text('3 Months'), findsOneWidget);
      expect(find.text('6 Months'), findsOneWidget);
      expect(find.text('1 Year'), findsOneWidget);
      expect(find.text('Punches required'), findsOneWidget);
      expect(find.text('Reward description'), findsOneWidget);
      expect(find.text('Card color theme'), findsOneWidget);
      expect(find.text('Punch method'), findsOneWidget);

      // New Price Setting Field
      expect(find.text('Price setting (per punch)'), findsOneWidget);
      expect(find.text('PKR'), findsOneWidget);
      expect(find.byKey(const Key('price_setting_input')), findsOneWidget);
      expect(
        find.text('Customers will get a punch when they spend more than this amount.'),
        findsOneWidget,
      );

      // Save Button
      expect(find.text('Save & Activate'), findsOneWidget);
    });

    testWidgets('Stepper increments and decrements price setting amount', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CreateCardScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Up arrow
      final upArrow = find.byKey(const Key('price_stepper_up'));
      expect(upArrow, findsOneWidget);
      await tester.tap(upArrow);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('400'), findsOneWidget);

      // Tap Down arrow twice
      final downArrow = find.byKey(const Key('price_stepper_down'));
      expect(downArrow, findsOneWidget);
      await tester.tap(downArrow);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('350'), findsOneWidget);

      await tester.tap(downArrow);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('300'), findsOneWidget);
    });

    testWidgets('Populates existing pricePerPunch and currency when editing', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const CreateCardScreen(
            cardId: 'card-123',
            initialData: {
              'id': 'card-123',
              'title': 'VIP Tea Club',
              'punchesRequired': 8,
              'rewardDescription': 'Free Premium Chai',
              'pricePerPunch': 500,
              'currency': 'USD',
              'validUntil': '2027-10-15T00:00:00.000Z',
              'visualStyle': {'theme': 'teal'},
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Edit Loyalty Card'), findsOneWidget);
      expect(find.text('VIP Tea Club'), findsWidgets);
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('500'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });
  });

  group('BusinessDashboardScreen Widget Tests', () {
    testWidgets('Renders dashboard structure correctly', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const BusinessDashboardScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(BusinessDashboardScreen), findsOneWidget);
    });
  });
}
