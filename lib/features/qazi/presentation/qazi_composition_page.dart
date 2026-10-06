import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../models/qazi_composition.dart';
import '../../../widgets/app_components.dart';
import '../../calculator/logic/prediction_engine.dart';

class QaziCompositionPage extends StatefulWidget {
  const QaziCompositionPage({super.key});

  @override
  State<QaziCompositionPage> createState() => _QaziCompositionPageState();
}

class _QaziCompositionPageState extends State<QaziCompositionPage> {
  final _formKey = GlobalKey<FormState>();
  final _total = TextEditingController();
  final _meat = TextEditingController();
  final _fat = TextEditingController();
  final _notes = TextEditingController();
  final _target = TextEditingController();
  final _engine = QaziPredictionEngine();
  int? _horseId;
  QaziComposition? _editing;
  QaziPrediction? _prediction;
  bool _saving = false;

  @override
  void dispose() {
    _total.dispose();
    _meat.dispose();
    _fat.dispose();
    _notes.dispose();
    _target.dispose();
    super.dispose();
  }

  double? _parse(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  String? _validateNumber(String? text, {bool required = false}) {
    if ((text == null || text.trim().isEmpty) && !required) {
      return null;
    }
    final value = _parse(text ?? '');
    if (value == null || !value.isFinite || value < 0) {
      return 'Noldan kichik bo‘lmagan son kiriting';
    }
    if (required && value <= 0) {
      return 'Qiymat 0 dan katta bo‘lishi kerak';
    }
    return null;
  }

  void _edit(QaziComposition item) {
    setState(() {
      _editing = item;
      _horseId = item.horseBatchId;
      _total.text = item.totalQaziKg.toString();
      _meat.text = item.meatKg.toString();
      _fat.text = item.fatKg.toString();
      _notes.text = item.notes;
    });
  }

  void _clear() {
    setState(() {
      _editing = null;
      _horseId = null;
      _total.clear();
      _meat.clear();
      _fat.clear();
      _notes.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final state = AppScope.of(context);
    final total = _parse(_total.text)!;
    final meat = _parse(_meat.text) ?? 0;
    final fat = _parse(_fat.text) ?? 0;
    if (meat + fat > total) {
      showMessage(
        context,
        'O‘lchangan go‘sht va yog‘ jami qazi vaznidan oshmasin.',
      );
      return;
    }
    final horseId = _horseId;
    if (horseId == null) {
      showMessage(context, 'Qazi kuzatuviga tegishli otni tanlang.');
      return;
    }
    final record = _editing ??
        QaziComposition(
          horseBatchId: horseId,
          createdAt: DateTime.now(),
          totalQaziKg: total,
          meatKg: meat,
          fatKg: fat,
        );
    record
      ..horseBatchId = horseId
      ..totalQaziKg = total
      ..meatKg = meat
      ..fatKg = fat
      ..notes = _notes.text.trim();
    setState(() => _saving = true);
    try {
      await state.database.saveQaziComposition(record);
      await state.reload();
      if (mounted) {
        _clear();
        showMessage(context, 'Qazi tarkibi saqlandi.');
      }
    } catch (error) {
      if (mounted) showMessage(context, 'Saqlab bo‘lmadi: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete(QaziComposition item) async {
    final state = AppScope.of(context);
    if (!await confirmAction(
      context,
      title: 'Qazi kuzatuvini o‘chirish',
      message: 'Tanlangan haqiqiy kuzatuv o‘chirilsinmi?',
    )) {
      return;
    }
    try {
      await state.database.deleteRecord('qazi_compositions', item.id!);
      await state.reload();
      if (mounted && _editing?.id == item.id) _clear();
    } catch (error) {
      if (mounted) showMessage(context, 'O‘chirib bo‘lmadi: $error');
    }
  }

  void _predict() {
    final target = _parse(_target.text);
    if (target == null || !target.isFinite || target <= 0) {
      showMessage(
        context,
        'Tahlil qilinadigan qazi miqdorini 0 dan katta kiriting.',
      );
      return;
    }
    setState(
      () =>
          _prediction = _engine.predict(AppScope.of(context).qaziCompositions),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final records = state.qaziCompositions;
    final horses = state.horses;
    return Scaffold(
      appBar: AppBar(title: const Text('Qazi tarkibi')),
      body: pageContent(
        title: 'Qazi tarkibi',
        subtitle:
            'Faqat real o‘lchangan tarkibni kiriting — miqdor prognoz qilinmaydi',
        children: [
          SectionCard(
            title: _editing == null ? 'Yangi kuzatuv' : 'Kuzatuvni tahrirlash',
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _horseId,
                    decoration: const InputDecoration(
                      labelText: 'Bog‘langan ot',
                    ),
                    items: horses
                        .where((horse) => horse.id != null)
                        .map(
                          (horse) => DropdownMenuItem(
                            value: horse.id,
                            child: Text(horse.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _horseId = value),
                  ),
                  const SizedBox(height: 12),
                  _numberField(_total, 'Jami qazi', required: true),
                  const SizedBox(height: 12),
                  _numberField(_meat, 'O‘lchangan go‘sht'),
                  const SizedBox(height: 12),
                  _numberField(_fat, 'O‘lchangan yog‘'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notes,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Izoh (ixtiyoriy)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: const Icon(Icons.save_outlined),
                          label: Text(_saving ? 'Saqlanmoqda…' : 'Saqlash'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: _clear,
                        child: const Text('Tozalash'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Haqiqiy qazi kuzatuvlari',
            child: records.isEmpty
                ? const EmptyState(
                    icon: Icons.restaurant_outlined,
                    title: 'Hali qazi tarkibi kiritilmagan',
                  )
                : Column(
                    children: records.map((item) {
                      final matchingHorses = horses.where(
                        (entry) => entry.id == item.horseBatchId,
                      );
                      final horse =
                          matchingHorses.isEmpty ? null : matchingHorses.first;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${formatKg(item.totalQaziKg)} · ${horse?.name ?? 'Ot #${item.horseBatchId}'}',
                        ),
                        subtitle: Text(
                          'Go‘sht ${formatKg(item.meatKg)} (${item.meatPercent.toStringAsFixed(1)}%) · '
                          'yog‘ ${formatKg(item.fatKg)} (${item.fatPercent.toStringAsFixed(1)}%)\n'
                          '${item.createdAt.toLocal().toString().substring(0, 10)}',
                        ),
                        isThreeLine: true,
                        onTap: () => _edit(item),
                        trailing: IconButton(
                          tooltip: 'O‘chirish',
                          onPressed: () => _delete(item),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Tarixiy tarkib tahlili',
            child: Column(
              children: [
                TextField(
                  controller: _target,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Tahlil qilinadigan qazi (kg)',
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: _predict,
                  icon: const Icon(Icons.insights),
                  label: const Text('Haqiqiy tarixni tahlil qilish'),
                ),
                const SizedBox(height: 10),
                Text(
                  _prediction == null
                      ? 'Prognoz kafolat emas va kamida 5 ta haqiqiy kuzatuv talab qiladi.'
                      : !_prediction!.hasEnoughData
                          ? 'Yetarli ma’lumot yo‘q: ${_prediction!.sampleCount}/5 kuzatuv.'
                          : 'Taxminiy tarkib: go‘sht ${_prediction!.predictedMeat(_parse(_target.text) ?? 0).toStringAsFixed(2)} kg · '
                              'yog‘ ${_prediction!.predictedFat(_parse(_target.text) ?? 0).toStringAsFixed(2)} kg. '
                              'Namuna ${_prediction!.sampleCount} · ishonchlilik ${_prediction!.confidence.toStringAsFixed(0)}%.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    bool required = false,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]'))
        ],
        decoration: InputDecoration(labelText: label, suffixText: 'kg'),
        validator: (value) => _validateNumber(value, required: required),
      );
}
