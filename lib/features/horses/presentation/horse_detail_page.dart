import 'package:flutter/material.dart';

import '../../../app/app_state.dart';
import '../../../models/horse_batch.dart';
import '../../../widgets/app_components.dart';

class HorseDetailPage extends StatelessWidget {
  const HorseDetailPage({required this.horse, super.key});

  final HorseBatch horse;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final qazi = state.qaziCompositions
        .where((entry) => entry.horseBatchId == horse.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Scaffold(
      appBar: AppBar(title: const Text('Ot ma’lumotlari')),
      body: pageContent(
        title: horse.name,
        subtitle:
            'Yaratilgan ${horse.createdAt.toLocal().toString().substring(0, 16)}',
        children: [
          SectionCard(
            title: 'Umumiy ma’lumotlar',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 540 ? 3 : 2;
                final tileWidth =
                    (constraints.maxWidth - (columns - 1) * 10) / columns;
                return GridView.count(
                  crossAxisCount: columns,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisExtent: tileWidth < 220 ? 76 : 128,
                  children: [
                    MetricTile(
                      label: 'Tirik vazn',
                      value: formatKg(horse.liveWeightKg),
                      icon: Icons.monitor_weight_outlined,
                    ),
                    MetricTile(
                      label: 'Xarid narxi / kg',
                      value: formatMoney(horse.purchasePricePerKg),
                      icon: Icons.sell_outlined,
                    ),
                    MetricTile(
                      label: 'Xarid qiymati',
                      value: formatMoney(horse.totalPurchaseCost),
                      icon: Icons.payments_outlined,
                    ),
                    MetricTile(
                      label: 'O‘lchangan jami',
                      value:
                          '${formatKg(horse.totalMeasuredKg)} · ${horse.totalMeasuredPercent.toStringAsFixed(1)}%',
                      icon: Icons.inventory_2_outlined,
                    ),
                    MetricTile(
                      label: 'Hisobga olinmagan',
                      value: formatKg(horse.unaccountedWeightKg),
                      icon: Icons.scale_outlined,
                    ),
                    MetricTile(
                      label: 'Qazi',
                      value: horse.qaziKg > 0
                          ? formatKg(horse.qaziKg)
                          : 'Aniqlanmagan',
                      icon: Icons.restaurant_outlined,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Real o‘lchangan natijalar',
            child: Column(
              children: horse.measuredOutputs
                  .map(
                    (entry) => _DetailRow(
                      label: entry.$1,
                      value:
                          '${formatKg(entry.$2)} · ${horse.percent(entry.$2).toStringAsFixed(2)}%',
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: 'Qazi tarkibi',
            child: qazi.isEmpty
                ? const Text(
                    'Bu ot uchun haqiqiy qazi tarkibi hali qayd etilmagan.',
                  )
                : Column(
                    children: qazi
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.createdAt.toLocal().toString().substring(0, 10)} · ${formatKg(item.totalQaziKg)}',
                                ),
                                Text(
                                  'Go‘sht ${formatKg(item.meatKg)} (${item.meatPercent.toStringAsFixed(1)}%) · '
                                  'yog‘ ${formatKg(item.fatKg)} (${item.fatPercent.toStringAsFixed(1)}%)',
                                ),
                                if (item.notes.isNotEmpty) Text(item.notes),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          if (horse.notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            SectionCard(title: 'Izoh', child: Text(horse.notes)),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await confirmAction(
                context,
                title: 'Ot qaydini o‘chirish',
                message:
                    'Ushbu ot va unga bog‘langan o‘lchov, qazi kuzatuvi hamda xarajatlar o‘chirilsinmi?',
              );
              if (!confirmed || !context.mounted) return;
              try {
                await state.database.deleteHorseBatch(horse.id!);
                await state.reload();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              } catch (error) {
                if (context.mounted) {
                  showMessage(context, 'O‘chirib bo‘lmadi: $error');
                }
              }
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Ot qaydini o‘chirish'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
