import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../models/processing_result.dart';
import '../../widgets/app_components.dart';
import '../../widgets/date_range_selector.dart';
import '../calculator/logic/prediction_engine.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final _targetController = TextEditingController();
  DateRange _range = DateRange(
    start: DateUtils.dateOnly(DateTime.now()),
    endExclusive:
        DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1)),
    label: 'Bugun',
  );
  double? _target;

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final results = state.results
        .where(
          (item) =>
              _range.contains(item.createdAt) &&
              item.liveWeightKg.isFinite &&
              item.liveWeightKg > 0,
        )
        .toList();
    final horses =
        state.horses.where((item) => _range.contains(item.createdAt)).length;
    final liveWeights = results.map((item) => item.liveWeightKg).toList();
    final targetResults = _target == null
        ? <ProcessingResult>[]
        : results
            .where((item) => (item.liveWeightKg - _target!).abs() <= 50)
            .toList();
    final prediction = _target == null || targetResults.length < 5
        ? null
        : PredictionEngine().predict(targetResults, _target!);

    return pageContent(
      title: 'Statistika',
      subtitle: 'Tahlil faqat saqlangan real o‘lchovlardan hisoblanadi',
      children: [
        SectionCard(
          title: 'Davr',
          child: DateRangeSelector(
            onChanged: (range) => setState(() => _range = range),
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Haqiqiy natijalar · ${_range.label}',
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 540 ? 3 : 2;
                  return GridView.count(
                    crossAxisCount: columns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: columns == 2 ? 1.65 : 1.8,
                    children: [
                      MetricTile(
                        label: 'Qayta ishlangan otlar',
                        value: '$horses',
                        icon: Icons.pets_outlined,
                      ),
                      MetricTile(
                        label: 'O‘lchovlar',
                        value: '${results.length}',
                        icon: Icons.fact_check_outlined,
                      ),
                      MetricTile(
                        label: 'Jami tirik vazn',
                        value: formatKg(_sum(liveWeights)),
                        icon: Icons.monitor_weight_outlined,
                      ),
                      MetricTile(
                        label: 'O‘rtacha tirik vazn',
                        value: results.isEmpty
                            ? '—'
                            : formatKg(_mean(liveWeights)),
                        icon: Icons.analytics_outlined,
                      ),
                      MetricTile(
                        label: 'Median vazn',
                        value: results.isEmpty
                            ? '—'
                            : formatKg(_median(liveWeights)),
                        icon: Icons.balance_outlined,
                      ),
                      MetricTile(
                        label: 'Min / max',
                        value: results.isEmpty
                            ? '—'
                            : '${formatKg(_min(liveWeights), decimals: 0)} / ${formatKg(_max(liveWeights), decimals: 0)}',
                        icon: Icons.swap_vert,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Vazn standart og‘ishi: ${results.isEmpty ? '—' : formatKg(_standardDeviation(liveWeights))}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Mahsulotlar · tarixiy taqsimot',
          child: results.isEmpty
              ? const EmptyState(
                  icon: Icons.insights_outlined,
                  title: 'Statistika uchun real qaydlar kerak',
                )
              : Column(
                  children: List.generate(PredictionEngine.outputNames.length, (
                    index,
                  ) {
                    final values = results
                        .map((item) => item.measuredOutputs[index].$2)
                        .where((value) => value.isFinite && value >= 0)
                        .toList();
                    final percentages = results
                        .where((item) => item.liveWeightKg > 0)
                        .map(
                          (item) =>
                              item.measuredOutputs[index].$2 /
                              item.liveWeightKg *
                              100,
                        )
                        .where((value) => value.isFinite && value >= 0)
                        .toList();
                    return _StatisticsMetric(
                      name: PredictionEngine.outputNames[index],
                      average: _mean(values),
                      median: _median(values),
                      minimum: _min(values),
                      maximum: _max(values),
                      averagePercent: _mean(percentages),
                      deviation: _standardDeviation(values),
                      count: values.length,
                    );
                  }),
                ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Muayyan vazn tahlili',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Maqsad vaznidan 50 kg ichidagi real otlar bo‘yicha hisoblanadi. Kamida 5 kuzatuv zarur.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _targetController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Maqsad vazn',
                        suffixText: 'kg',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () {
                      final value = double.tryParse(
                        _targetController.text.trim().replaceAll(',', '.'),
                      );
                      if (value == null || !value.isFinite || value <= 0) {
                        showMessage(
                          context,
                          'Maqsad vaznni 0 dan katta kiriting.',
                        );
                        return;
                      }
                      setState(() => _target = value);
                    },
                    child: const Text('Tahlil'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _target == null
                    ? 'Maqsad vaznni kiriting.'
                    : targetResults.length < 5
                        ? '50 kg oralig‘idagi ${targetResults.length}/5 haqiqiy kuzatuv.'
                        : '${targetResults.length} kuzatuv · 50 kg oralig‘i.',
              ),
              if (prediction != null) ...[
                const SizedBox(height: 10),
                ...prediction.metrics.entries.map(
                  (entry) => _StatisticsMetric(
                    name: entry.key,
                    average: entry.value.kilogramsFor(_target!),
                    median: entry.value.percent,
                    minimum: 0,
                    maximum: 0,
                    averagePercent: entry.value.percent,
                    deviation: entry.value.standardDeviation,
                    count: entry.value.sampleCount,
                    prediction: true,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatisticsMetric extends StatelessWidget {
  const _StatisticsMetric({
    required this.name,
    required this.average,
    required this.median,
    required this.minimum,
    required this.maximum,
    required this.averagePercent,
    required this.deviation,
    required this.count,
    this.prediction = false,
  });

  final String name;
  final double average;
  final double median;
  final double minimum;
  final double maximum;
  final double averagePercent;
  final double deviation;
  final int count;
  final bool prediction;

  @override
  Widget build(BuildContext context) => ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          prediction
              ? 'Taxmin ${formatKg(average)} · ${averagePercent.toStringAsFixed(2)}%'
              : 'O‘rtacha ${formatKg(average)} · ${averagePercent.toStringAsFixed(2)}%',
        ),
        children: [
          if (prediction)
            ListTile(
              dense: true,
              title: const Text('Standart og‘ish / namuna / ishonchlilik'),
              subtitle: Text(
                '${deviation.toStringAsFixed(2)} p.p. · $count · '
                '${((1 - math.exp(-count / 50)) / (1 + deviation) * 100).clamp(0, 100).toStringAsFixed(0)}%',
              ),
            )
          else
            ListTile(
              dense: true,
              title: const Text('Median · min · max · standart og‘ish'),
              subtitle: Text(
                '${formatKg(median)} · ${formatKg(minimum)} · ${formatKg(maximum)} · ${formatKg(deviation)} · $count ta',
              ),
            ),
        ],
      );
}

double _sum(List<double> values) => values.fold(0, (sum, value) => sum + value);
double _mean(List<double> values) =>
    values.isEmpty ? 0 : _sum(values) / values.length;
double _min(List<double> values) =>
    values.isEmpty ? 0 : values.reduce((a, b) => a < b ? a : b);
double _max(List<double> values) =>
    values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);

double _median(List<double> values) {
  if (values.isEmpty) return 0;
  final sorted = List<double>.of(values)..sort();
  final middle = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[middle]
      : (sorted[middle - 1] + sorted[middle]) / 2;
}

double _standardDeviation(List<double> values) {
  if (values.length < 2) return 0;
  final mean = _mean(values);
  return math.sqrt(
    _sum(values.map((value) => math.pow(value - mean, 2).toDouble()).toList()) /
        (values.length - 1),
  );
}
