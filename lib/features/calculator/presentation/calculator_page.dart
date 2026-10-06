import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../models/horse_batch.dart';
import '../../../models/processing_result.dart';
import '../../../widgets/app_components.dart';
import '../logic/calculation_engine.dart';
import '../logic/prediction_engine.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  final _formKey = GlobalKey<FormState>();
  final _horseName = TextEditingController();
  final _liveWeight = TextEditingController();
  final _purchasePrice = TextEditingController();
  final _notes = TextEditingController();
  final _measurements = List.generate(7, (_) => TextEditingController());
  final _engine = CalculationEngine();
  final _predictionEngine = PredictionEngine();
  final _qaziEngine = QaziPredictionEngine();
  ProcessingResult? _result;
  ProductionPrediction? _productionPrediction;
  QaziPrediction? _qaziPrediction;
  double _purchasePriceValue = 0;
  String? _validationMessage;
  bool _saved = false;
  bool _saving = false;

  @override
  void dispose() {
    _horseName.dispose();
    _liveWeight.dispose();
    _purchasePrice.dispose();
    _notes.dispose();
    for (final controller in _measurements) {
      controller.dispose();
    }
    super.dispose();
  }

  double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  String? _numberValidator(
    String? text, {
    bool required = false,
  }) {
    if ((text == null || text.trim().isEmpty) && !required) return null;
    final value = _parse(text ?? '');
    if (value == null || !value.isFinite) return 'To‘g‘ri son kiriting';
    if (value < 0) return 'Manfiy qiymat kiritmang';
    if (required && value <= 0) return 'Qiymat 0 dan katta bo‘lishi kerak';
    return null;
  }

  ProcessingResult _readResult() => ProcessingResult(
        horseBatchId: 0,
        createdAt: DateTime.now(),
        liveWeightKg: _parse(_liveWeight.text)!,
        cleanMeatKg: _parse(_measurements[0].text) ?? 0,
        fatKg: _parse(_measurements[1].text) ?? 0,
        boneKg: _parse(_measurements[2].text) ?? 0,
        tendonKg: _parse(_measurements[3].text) ?? 0,
        kachalkaKg: _parse(_measurements[4].text) ?? 0,
        tarashKg: _parse(_measurements[5].text) ?? 0,
        wasteKg: _parse(_measurements[6].text) ?? 0,
      );

  void _calculate() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final result = _readResult();
    final error = _engine.validate(result);
    if (error != null) {
      setState(() => _validationMessage = error);
      return;
    }
    final state = AppScope.of(context);
    setState(() {
      _validationMessage = null;
      _result = result;
      _saved = false;
      _purchasePriceValue = _parse(_purchasePrice.text) ?? 0;
      _productionPrediction = _predictionEngine.predict(
        state.results,
        result.liveWeightKg,
      );
      _qaziPrediction = _qaziEngine.predict(state.qaziCompositions);
    });
  }

  Future<void> _save() async {
    final result = _result;
    if (result == null || _saved || _saving) return;
    final error = _engine.validate(result);
    if (error != null) {
      setState(() => _validationMessage = error);
      return;
    }
    final state = AppScope.of(context);
    setState(() => _saving = true);
    final now = DateTime.now();
    final horse = HorseBatch(
      name: _horseName.text.trim().isEmpty
          ? 'Ot-${now.millisecondsSinceEpoch}'
          : _horseName.text.trim(),
      createdAt: now,
      liveWeightKg: result.liveWeightKg,
      purchasePricePerKg: _purchasePriceValue,
      cleanMeatKg: result.cleanMeatKg,
      fatKg: result.fatKg,
      boneKg: result.boneKg,
      tendonKg: result.tendonKg,
      kachalkaKg: result.kachalkaKg,
      tarashKg: result.tarashKg,
      wasteKg: result.wasteKg,
      notes: _notes.text.trim(),
    );
    try {
      await state.database.saveHorseAndResult(horse, result);
      await state.reload();
      if (mounted) {
        setState(() => _saved = true);
        showMessage(context, 'O‘lchovlar saqlandi.');
      }
    } catch (error) {
      if (mounted) showMessage(context, 'Saqlab bo‘lmadi: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => pageContent(
        title: 'Qayta ishlash',
        subtitle: 'Faqat real o‘lchangan natijalarni kiriting',
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                SectionCard(
                  title: 'Ot ma’lumotlari',
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _horseName,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Ot nomi yoki raqami',
                          hintText: 'Masalan: Ot-001',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _liveWeight,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Tirik vazni',
                          suffixText: 'kg',
                        ),
                        validator: (value) =>
                            _numberValidator(value, required: true),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _purchasePrice,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        decoration: const InputDecoration(
                          labelText: '1 kg xarid narxi',
                          suffixText: 'so‘m',
                        ),
                        validator: _numberValidator,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SectionCard(
                  title: 'Real natijalar',
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth > 520 ? 2 : 1;
                      return GridView.builder(
                        itemCount: _measurements.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 4,
                          mainAxisExtent: 76,
                        ),
                        itemBuilder: (context, index) => TextFormField(
                          controller: _measurements[index],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]')),
                          ],
                          decoration: InputDecoration(
                            labelText: PredictionEngine.outputNames[index],
                            suffixText: 'kg',
                          ),
                          validator: _numberValidator,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                SectionCard(
                  title: 'Izoh',
                  child: TextFormField(
                    controller: _notes,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Ot haqida qo‘shimcha qaydlar',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_validationMessage != null) ...[
            Text(
              _validationMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 8),
          ],
          FilledButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Hisoblash'),
          ),
          if (_result case final result?) ...[
            const SizedBox(height: 14),
            _ResultsCard(
              result: result,
              purchaseCost: result.liveWeightKg * _purchasePriceValue,
              productionPrediction: _productionPrediction,
              qaziPrediction: _qaziPrediction,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saved || _saving ? null : _save,
              icon: Icon(_saved ? Icons.check : Icons.save_outlined),
              label: Text(
                _saving
                    ? 'Saqlanmoqda…'
                    : _saved
                        ? 'Saqlandi'
                        : 'Natijani saqlash',
              ),
            ),
          ],
        ],
      );
}

class _ResultsCard extends StatelessWidget {
  const _ResultsCard({
    required this.result,
    required this.purchaseCost,
    required this.productionPrediction,
    required this.qaziPrediction,
  });

  final ProcessingResult result;
  final double purchaseCost;
  final ProductionPrediction? productionPrediction;
  final QaziPrediction? qaziPrediction;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          SectionCard(
            title: 'Hisoblangan natija',
            child: Column(
              children: [
                _ResultRow(
                  label: 'Tirik vazn',
                  value: formatKg(result.liveWeightKg),
                ),
                _ResultRow(
                  label: 'Xarid qiymati',
                  value: formatMoney(purchaseCost),
                ),
                const Divider(height: 20),
                ...result.measuredOutputs.map(
                  (entry) => _ResultRow(
                    label: entry.$1,
                    value:
                        '${formatKg(entry.$2)} · ${result.percent(entry.$2).toStringAsFixed(2)}%',
                  ),
                ),
                const Divider(height: 20),
                _ResultRow(
                  label: 'Jami real o‘lchov',
                  value:
                      '${formatKg(result.totalMeasuredKg)} · ${result.totalMeasuredPercent.toStringAsFixed(2)}%',
                ),
                _ResultRow(
                  label: 'Hisobga olinmagan vazn',
                  value: formatKg(result.unaccountedWeightKg),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Tarixiy ishlab chiqarish tahlili',
            child: productionPrediction == null ||
                    !productionPrediction!.hasEnoughData
                ? Text(
                    'Kamida 5 ta real qayd kerak. Hozirgi namuna: ${productionPrediction?.sampleCount ?? 0}/5.',
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Yaqin vaznli tarixiy kuzatuvlarga asoslangan taxmin; kafolatlangan natija emas.',
                      ),
                      const SizedBox(height: 8),
                      ...productionPrediction!.metrics.entries.map(
                        (entry) => _ResultRow(
                          label: entry.key,
                          value: !entry.value.hasEnoughData
                              ? 'Yetarli ma’lumot yo‘q (${entry.value.sampleCount}/5)'
                              : '${formatKg(entry.value.kilogramsFor(result.liveWeightKg))} · '
                                  '${entry.value.percent.toStringAsFixed(1)}%',
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Qazi tarkibi · real kuzatuvlar',
            child: qaziPrediction == null || !qaziPrediction!.hasEnoughData
                ? Text(
                    'Qazini hisobga qo‘shmang. Tarkib uchun kamida 5 ta o‘lchangan qazi kuzatuvi kerak (${qaziPrediction?.sampleCount ?? 0}/5).',
                  )
                : Text(
                    '1 kg qazi uchun tarixiy o‘rtacha go‘sht ${qaziPrediction!.meatPerKg.toStringAsFixed(3)} kg, '
                    'yog‘ ${qaziPrediction!.fatPerKg.toStringAsFixed(3)} kg. '
                    'Namuna ${qaziPrediction!.sampleCount}; ishonchlilik ${qaziPrediction!.confidence.toStringAsFixed(0)}%. '
                    'Bu qazi miqdorini prognoz qilmaydi.',
                  ),
          ),
        ],
      );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
}
