import 'package:adenalin_calculator/app/app_state.dart';
import 'package:adenalin_calculator/features/analytics/reports_page.dart';
import 'package:adenalin_calculator/features/analytics/statistics_page.dart';
import 'package:adenalin_calculator/features/horses/presentation/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('summary and analysis cards do not overflow on a small phone',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState(await SharedPreferences.getInstance());

    for (final page in [
      const DashboardPage(),
      const StatisticsPage(),
      const ReportsPage(),
    ]) {
      await tester.pumpWidget(
        AppScope(
          state: state,
          child: MaterialApp(home: Scaffold(body: page)),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('summary cards fit a tablet portrait layout', (tester) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppState(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      AppScope(
        state: state,
        child: const MaterialApp(
          home: Scaffold(body: DashboardPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
