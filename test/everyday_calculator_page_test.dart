import 'package:adenalin_calculator/app/app_state.dart';
import 'package:adenalin_calculator/features/calculator/presentation/everyday_calculator_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'calculator_haptics': false});
  });

  Future<AppState> createState() async =>
      AppState(await SharedPreferences.getInstance());

  Future<void> launch(
    WidgetTester tester, {
    Size size = const Size(360, 640),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = await createState();
    state.hapticFeedback = false;
    await tester.pumpWidget(
      AppScope(
        state: state,
        child: const MaterialApp(home: EverydayCalculatorPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String key) async {
    final finder = find.text(key).last;
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
  }

  testWidgets('evaluates expressions and repeats the last operation',
      (tester) async {
    await launch(tester);
    for (final key in ['2', '+', '3', '=']) {
      await tapKey(tester, key);
    }
    expect(find.text('2+3'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(Card), matching: find.text('5')),
      findsOneWidget,
    );
    await tapKey(tester, '=');
    expect(
      find.descendant(of: find.byType(Card), matching: find.text('8')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows division-by-zero feedback', (tester) async {
    await launch(tester);
    for (final key in ['4', '÷', '0', '=']) {
      await tapKey(tester, key);
    }
    expect(find.text('Nolga bo‘lish mumkin emas.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history results can be reused in a new calculation',
      (tester) async {
    await launch(tester);
    for (final key in ['2', '+', '3', '=']) {
      await tapKey(tester, key);
    }
    await tester.tap(find.byTooltip('Hisoblar tarixi'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    for (final key in ['+', '4', '=']) {
      await tapKey(tester, key);
    }
    expect(
      find.descendant(of: find.byType(Card), matching: find.text('9')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('calculator fits a compact phone viewport', (tester) async {
    await launch(tester, size: const Size(320, 568));
    expect(find.text('Oddiy kalkulyator'), findsOneWidget);
    expect(find.text('='), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calculator adapts to landscape phone layout', (tester) async {
    await launch(tester, size: const Size(800, 360));
    expect(find.text('Oddiy kalkulyator'), findsOneWidget);
    expect(find.text('='), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
