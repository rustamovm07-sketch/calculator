import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../widgets/app_components.dart';
import '../../widgets/date_range_selector.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateRange _range = DateRange(
    start: DateUtils.dateOnly(DateTime.now()),
    endExclusive:
        DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1)),
    label: 'Bugun',
  );

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final horses =
        state.horses.where((item) => _range.contains(item.createdAt)).toList();
    final results = state.results
        .where(
          (item) =>
              _range.contains(item.createdAt) &&
              item.liveWeightKg.isFinite &&
              item.liveWeightKg > 0,
        )
        .toList();
    final expenses = state.expenses
        .where((item) => _range.contains(item.createdAt))
        .toList();
    final totalWeight = results.fold<double>(
      0,
      (sum, item) => sum + item.liveWeightKg,
    );
    final totalProduction = results.fold<double>(
      0,
      (sum, item) => sum + item.totalMeasuredKg,
    );
    final purchaseCost = horses.fold<double>(
      0,
      (sum, item) => sum + item.totalPurchaseCost,
    );
    final expenseTotal = expenses.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    return pageContent(
      title: 'Hisobotlar',
      subtitle: 'Tanlangan davrdagi saqlangan ma’lumotlar',
      children: [
        SectionCard(
          title: 'Davr',
          child: DateRangeSelector(
            onChanged: (range) => setState(() => _range = range),
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: _range.label,
          child: LayoutBuilder(
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
                    value: '${horses.length}',
                    icon: Icons.pets_outlined,
                  ),
                  MetricTile(
                    label: 'O‘lchov yozuvlari',
                    value: '${results.length}',
                    icon: Icons.fact_check_outlined,
                  ),
                  MetricTile(
                    label: 'Tirik vazn',
                    value: formatKg(totalWeight),
                    icon: Icons.monitor_weight_outlined,
                  ),
                  MetricTile(
                    label: 'Real mahsulot',
                    value: formatKg(totalProduction),
                    icon: Icons.inventory_2_outlined,
                  ),
                  MetricTile(
                    label: 'Ot xaridi',
                    value: formatMoney(purchaseCost),
                    icon: Icons.shopping_cart_outlined,
                  ),
                  MetricTile(
                    label: 'Xarajatlar',
                    value: formatMoney(expenseTotal),
                    icon: Icons.receipt_long_outlined,
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: 'Davr o‘rtachalari',
          child: Column(
            children: [
              _ReportRow(
                label: 'O‘rtacha tirik vazn',
                value: results.isEmpty
                    ? 'Ma’lumot yo‘q'
                    : formatKg(totalWeight / results.length),
              ),
              _ReportRow(
                label: 'O‘rtacha real mahsulot',
                value: results.isEmpty
                    ? 'Ma’lumot yo‘q'
                    : formatKg(totalProduction / results.length),
              ),
              _ReportRow(
                label: 'O‘rtacha xarajat',
                value: expenses.isEmpty
                    ? 'Ma’lumot yo‘q'
                    : formatMoney(expenseTotal / expenses.length),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const SectionCard(
          title: 'Daromad va foyda',
          child: Text(
            'Sotuv tranzaksiyalari mavjud emas. Shu sababli tushum va foyda hisoblanmaydi. Ishlab chiqarish miqdorlari faqat real ProcessingResult o‘lchovlaridan olinadi.',
          ),
        ),
      ],
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.label, required this.value});
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
