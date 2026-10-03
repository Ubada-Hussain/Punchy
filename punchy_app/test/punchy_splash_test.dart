import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:punchy_app/features/system_states/splash/splash_page.dart';
import 'package:punchy_app/features/system_states/splash/splash_painters.dart';
import 'package:punchy_app/features/system_states/splash/splash_stage.dart';

Future<void> mountIntro(
  WidgetTester tester,
  Completer<void> initialization,
  VoidCallback onReady, {
  bool reduced = false,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: reduced,
          textScaler: TextScaler.linear(textScale),
        ),
        child: PunchyIntroPage(
          initialization: initialization.future,
          onReady: onReady,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('ready initialization waits for intro and 250ms handoff fade', (
    tester,
  ) async {
    final initialization = Completer<void>()..complete();
    var handoffs = 0;
    await mountIntro(tester, initialization, () => handoffs++);
    await tester.pump(const Duration(milliseconds: 2099));
    expect(handoffs, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(handoffs, 0);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(); // First tick of the reused controller's fade phase.
    await tester.pump(const Duration(milliseconds: 249));
    expect(handoffs, 0);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 16));
    expect(handoffs, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(handoffs, 1);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
    'completed intro holds final frame until initialization finishes',
    (tester) async {
      final initialization = Completer<void>();
      var handoffs = 0;
      await mountIntro(tester, initialization, () => handoffs++);
      await tester.pump(const Duration(seconds: 3));
      expect(handoffs, 0);
      expect(tester.widget<SplashStage>(find.byType(SplashStage)).time, 1);
      initialization.complete();
      await tester.pump();
      await tester.pump();
      expect(handoffs, 0);
      await tester.pump(const Duration(milliseconds: 251));
      expect(handoffs, 1);
    },
  );

  testWidgets(
    'slow startup fades hint after 6s without moving the final logo',
    (tester) async {
      final initialization = Completer<void>();
      var handoffs = 0;
      await mountIntro(tester, initialization, () => handoffs++);
      await tester.pump(const Duration(seconds: 3));
      final logoPosition = tester.getTopLeft(find.byType(Image));
      await tester.pump(const Duration(milliseconds: 2999));
      expect(find.text('Still loading...'), findsNothing);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('Still loading...'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.getTopLeft(find.byType(Image)), logoPosition);
      expect(tester.widget<SplashStage>(find.byType(SplashStage)).time, 1);
      expect(handoffs, 0);
      initialization.complete();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 251));
      expect(handoffs, 1);
    },
  );

  testWidgets('reduced motion uses 300ms fade and omits decorative burst', (
    tester,
  ) async {
    final initialization = Completer<void>()..complete();
    var handoffs = 0;
    await mountIntro(tester, initialization, () => handoffs++, reduced: true);
    expect(
      tester.widget<SplashStage>(find.byType(SplashStage)).reducedMotion,
      isTrue,
    );
    expect(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is SplashBurstPainter,
      ),
      findsNothing,
    );
    await tester.pump(const Duration(milliseconds: 299));
    expect(handoffs, 0);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 249));
    expect(handoffs, 0);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 16));
    expect(handoffs, 1);
  });

  testWidgets('360px screen ignores text scaling and exposes one brand label', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    final initialization = Completer<void>();
    await mountIntro(tester, initialization, () {}, textScale: 3);
    await tester.pump(const Duration(seconds: 3));
    expect(tester.getSize(find.byType(SplashStage)), const Size(150, 170));
    final textContext = tester.element(find.text('P'));
    expect(MediaQuery.textScalerOf(textContext).scale(52), 52);
    expect(
      find.bySemanticsLabel('Punchy, the ultimate loyalty app'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
    initialization.complete();
    await tester.pump();
  });

  testWidgets('disposing splash cancels timer and pending startup handoff', (
    tester,
  ) async {
    final initialization = Completer<void>();
    var handoffs = 0;
    await mountIntro(tester, initialization, () => handoffs++);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpWidget(const SizedBox());
    initialization.complete();
    await tester.pump(const Duration(seconds: 7));
    expect(handoffs, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'slow startup while ticker is muted cannot replace the unfinished intro',
    (tester) async {
      final initialization = Completer<void>();
      final visible = ValueNotifier(false);
      var handoffs = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: visible,
            child: PunchyIntroPage(
              initialization: initialization.future,
              onReady: () => handoffs++,
            ),
            builder: (_, enabled, child) =>
                TickerMode(enabled: enabled, child: child!),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 7));
      expect(handoffs, 0);
      visible.value = true;
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(tester.widget<SplashStage>(find.byType(SplashStage)).time, 1);
      initialization.complete();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 251));
      expect(handoffs, 1);
      await tester.pumpWidget(const SizedBox());
      visible.dispose();
    },
  );
}
