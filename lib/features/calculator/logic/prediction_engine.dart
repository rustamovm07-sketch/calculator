import 'dart:math' as math;

import '../../../models/processing_result.dart';
import '../../../models/qazi_composition.dart';

class PredictionMetric {
  const PredictionMetric({
    required this.percent,
    required this.standardDeviation,
    required this.sampleCount,
    required this.confidence,
  });

  final double percent;
  final double standardDeviation;
  final int sampleCount;
  final double confidence;

  bool get hasEnoughData => sampleCount >= 5;
  double kilogramsFor(double weight) =>
      hasEnoughData ? weight * percent / 100 : 0;
}

class ProductionPrediction {
  const ProductionPrediction({
    required this.sampleCount,
    required this.metrics,
  });

  final int sampleCount;
  final Map<String, PredictionMetric> metrics;
  bool get hasEnoughData => sampleCount >= 5;
}

class QaziPrediction {
  const QaziPrediction({
    required this.sampleCount,
    required this.meatPerKg,
    required this.fatPerKg,
    required this.meatStandardDeviation,
    required this.fatStandardDeviation,
    required this.confidence,
  });

  final int sampleCount;
  final double meatPerKg;
  final double fatPerKg;
  final double meatStandardDeviation;
  final double fatStandardDeviation;
  final double confidence;

  bool get hasEnoughData => sampleCount >= 5;
  double predictedMeat(double qaziKg) => qaziKg * meatPerKg;
  double predictedFat(double qaziKg) => qaziKg * fatPerKg;
}

class PredictionEngine {
  static const outputNames = [
    'Toza go‘sht',
    'Yog‘',
    'Suyak',
    'Pay',
    'Kachalka',
    'Tarash',
    'Chiqindi',
  ];

  ProductionPrediction predict(
    Iterable<ProcessingResult> results,
    double targetWeightKg,
  ) {
    if (!targetWeightKg.isFinite || targetWeightKg <= 0) {
      throw ArgumentError.value(targetWeightKg, 'targetWeightKg');
    }
    final data = results
        .where(
          (result) => result.liveWeightKg.isFinite && result.liveWeightKg > 0,
        )
        .toList();
    final metrics = <String, PredictionMetric>{};
    for (var index = 0; index < outputNames.length; index++) {
      final weighted = data
          .map((result) {
            final value =
                result.measuredOutputs[index].$2 / result.liveWeightKg * 100;
            return (
              value,
              1 / (1 + (result.liveWeightKg - targetWeightKg).abs()),
            );
          })
          .where((entry) => entry.$1.isFinite && entry.$1 >= 0)
          .toList();
      final totalWeight = weighted.fold<double>(
        0,
        (sum, entry) => sum + entry.$2,
      );
      final mean = totalWeight > 0
          ? weighted.fold<double>(
                0,
                (sum, entry) => sum + entry.$1 * entry.$2,
              ) /
              totalWeight
          : 0.0;
      final variance = totalWeight > 0
          ? weighted.fold<double>(
                0,
                (sum, entry) =>
                    sum + entry.$2 * (entry.$1 - mean) * (entry.$1 - mean),
              ) /
              totalWeight
          : 0;
      final deviation = math.sqrt(
        variance.clamp(0, double.infinity).toDouble(),
      );
      final count = weighted.length;
      final confidence = count < 5
          ? 0.0
          : ((1 - math.exp(-count / 50)) / (1 + deviation) * 100)
              .clamp(0, 100)
              .toDouble();
      metrics[outputNames[index]] = PredictionMetric(
        percent: mean,
        standardDeviation: deviation,
        sampleCount: count,
        confidence: confidence,
      );
    }
    return ProductionPrediction(sampleCount: data.length, metrics: metrics);
  }
}

class QaziPredictionEngine {
  QaziPrediction predict(Iterable<QaziComposition> observations) {
    final data = observations.where(
      (item) =>
          item.totalQaziKg.isFinite &&
          item.totalQaziKg > 0 &&
          item.meatKg.isFinite &&
          item.meatKg >= 0 &&
          item.fatKg.isFinite &&
          item.fatKg >= 0 &&
          item.meatKg + item.fatKg <= item.totalQaziKg,
    );
    final meat = data.map((item) => item.meatPerQaziKg).toList();
    final fat = data.map((item) => item.fatPerQaziKg).toList();
    final meatStats = _statistics(meat);
    final fatStats = _statistics(fat);
    final count = meat.length;
    final averageDeviation = (meatStats.$2 + fatStats.$2) / 2;
    final confidence = count < 5
        ? 0.0
        : ((1 - math.exp(-count / 50)) / (1 + averageDeviation) * 100)
            .clamp(0, 100)
            .toDouble();
    return QaziPrediction(
      sampleCount: count,
      meatPerKg: meatStats.$1,
      fatPerKg: fatStats.$1,
      meatStandardDeviation: meatStats.$2,
      fatStandardDeviation: fatStats.$2,
      confidence: confidence,
    );
  }

  (double, double) _statistics(List<double> values) {
    if (values.isEmpty) return (0, 0);
    final mean = values.reduce((a, b) => a + b) / values.length;
    if (values.length == 1) return (mean, 0);
    final variance = values.fold<double>(
          0,
          (sum, value) => sum + (value - mean) * (value - mean),
        ) /
        (values.length - 1);
    return (mean, math.sqrt(variance));
  }
}
