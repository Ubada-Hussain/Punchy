import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:punchy_app/core/providers/auth_provider.dart';
import 'package:punchy_app/features/auth/signup_screen.dart';
import 'package:punchy_app/features/shared/privacy_screen.dart';
import 'package:punchy_app/features/shared/terms_screen.dart';
import 'package:punchy_app/features/system_states/punchy_splash_screen.dart';
import 'package:punchy_app/features/system_states/offline_screen.dart';
import 'package:punchy_app/main.dart';

class _SignupAuth extends ChangeNotifier implements AuthProvider {
  bool ready = true;
  bool offline = false;

  @override
  bool get isReady => ready;
  @override
  bool get isOffline => offline;
  @override
  bool get isMaintenance => false;
  @override
  bool get isAuthenticated => false;
  @override
  bool get isLoading => false;
  @override
  bool get isSuspended => false;
  @override
  Map<String, dynamic>? get user => null;
  @override
  String? get errorMessage => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets(
    'real app router allows unauthenticated signup privacy navigation',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = _SignupAuth();
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: const PunchyApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Sign up'));
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Privacy Policy'));
      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();
      expect(find.byType(PrivacyScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'router refresh cannot bypass splash before intro and startup finish',
    (tester) async {
      final auth = _SignupAuth()..ready = false;
      addTearDown(auth.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: const PunchyApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      auth.offline = true;
      auth.notifyListeners();
      await tester.pump();
      expect(find.byType(PunchySplashScreen), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(PunchySplashScreen), findsOneWidget);
      auth.ready = true;
      auth.notifyListeners();
      await tester.pump();
      await tester.pump();
      expect(find.byType(PunchySplashScreen), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 251));
      await tester.pumpAndSettle();
      expect(find.byType(OfflineScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('both legal links use existing screens and preserve checkbox', (
    tester,
  ) async {
    // Default widget-test fonts have wider glyphs than the app's fonts.
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = _SignupAuth();
    final router = GoRouter(
      initialLocation: '/signup',
      routes: [
        GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),
        GoRoute(path: '/terms', builder: (_, _) => const TermsScreen()),
        GoRoute(path: '/privacy', builder: (_, _) => const PrivacyScreen()),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    final checkbox = find.byType(Checkbox);
    await tester.ensureVisible(checkbox);
    await tester.tap(checkbox);
    await tester.pump();
    expect(tester.widget<Checkbox>(checkbox).value, isTrue);
    final termsStyle = tester
        .widget<Text>(find.text('Terms & Conditions'))
        .style!;
    final privacyStyle = tester
        .widget<Text>(find.text('Privacy Policy'))
        .style!;
    expect(privacyStyle.color, termsStyle.color);
    expect(privacyStyle.fontWeight, termsStyle.fontWeight);
    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyScreen), findsOneWidget);
    expect(find.text('Your privacy matters'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(checkbox).value, isTrue);
    await tester.tap(find.text('Terms & Conditions'));
    await tester.pumpAndSettle();
    expect(find.byType(TermsScreen), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(checkbox).value, isTrue);
    await tester.tap(find.text('I agree to the '));
    await tester.pumpAndSettle();
    expect(find.byType(SignupScreen), findsOneWidget);
    expect(tester.widget<Checkbox>(checkbox).value, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
