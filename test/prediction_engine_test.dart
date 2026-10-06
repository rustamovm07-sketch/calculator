import 'package:adenalin_calculator/features/calculator/logic/prediction_engine.dart';
import 'package:adenalin_calculator/models/processing_result.dart';
import 'package:adenalin_calculator/models/qazi_composition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses weighted real processing results and requires five samples', () {
    final records = List.generate(
      5,
      (index) => ProcessingResult(
        horseBatchId: index,
        createdAt: DateTime(2026),
        liveWeightKg: 400,
        cleanMeatKg: 100,
      ),
    );
    final engine = PredictionEngine();

    final tooFew = engine.predict(records.take(4), 500);
    expect(tooFew.hasEnoughData, isFalse);
    expect(tooFew.metrics['Toza go‘sht']!.hasEnoughData, isFalse);

    final prediction = engine.predict(records, 500);
    expect(prediction.hasEnoughData, isTrue);
    expect(prediction.metrics['Toza go‘sht']!.percent, closeTo(25, 1e-8));
    expect(
      prediction.metrics['Toza go‘sht']!.kilogramsFor(500),
      closeTo(125, 1e-8),
    );
  });

  test('predicts qazi composition only from five valid measured records', () {
    final records = List.generate(
      5,
      (index) => QaziComposition(
        horseBatchId: index + 1,
        createdAt: DateTime(2026),
        totalQaziKg: 2,
        meatKg: 1,
        fatKg: .5,
      ),
    );
    final engine = QaziPredictionEngine();

    expect(engine.predict(records.take(4)).hasEnoughData, isFalse);
    final prediction = engine.predict(records);
    expect(prediction.hasEnoughData, isTrue);
    expect(prediction.meatPerKg, .5);
    expect(prediction.fatPerKg, .25);
    expect(prediction.predictedMeat(4), 2);
    expect(prediction.predictedFat(4), 1);
  });
}
