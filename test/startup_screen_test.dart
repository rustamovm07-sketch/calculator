import 'package:adenalin_calculator/app/app.dart';
import 'package:adenalin_calculator/app/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the branded startup screen while data loads',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState(await SharedPreferences.getInstance());
    await tester.pumpWidget(AdenalinCalculatorApp(state: state));

    expect(find.text('Adenalin Calculator'), findsOneWidget);
    expect(
        find.text('Hisob-kitob va ishlab chiqarish tahlili'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
