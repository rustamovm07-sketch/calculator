import 'package:adenalin_calculator/features/calculator/logic/calculation_engine.dart';
import 'package:adenalin_calculator/models/processing_result.dart';
import 'package:flutter_test/flutter_test.dart';

ProcessingResult result({
  double liveWeight = 400,
  double cleanMeat = 100,
  double fat = 40,
}) =>
    ProcessingResult(
      horseBatchId: 1,
      createdAt: DateTime(2026),
      liveWeightKg: liveWeight,
      cleanMeatKg: cleanMeat,
      fatKg: fat,
    );

void main() {
  final engine = CalculationEngine();

  test('calculates measured weight without estimated qazi', () {
    final value = result();

    expect(value.totalMeasuredKg, 140);
    expect(value.totalMeasuredPercent, 35);
    expect(value.unaccountedWeightKg, 260);
    expect(value.percent(value.cleanMeatKg), 25);
    expect(engine.validate(value), isNull);
  });

  test('rejects a non-positive live weight', () {
    expect(engine.validate(result(liveWeight: 0)), isNotNull);
  });

  test('rejects negative and non-finite measured values', () {
    expect(engine.validate(result()..wasteKg = -1), contains('manfiy'));
    expect(
      engine.validate(result()..wasteKg = double.infinity),
      contains('manfiy'),
    );
  });

  test('rejects measured outputs greater than the live weight', () {
    expect(
      engine.validate(result(liveWeight: 100, cleanMeat: 80, fat: 30)),
      contains('katta'),
    );
  });
}
