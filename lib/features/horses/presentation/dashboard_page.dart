import 'package:flutter/material.dart';

import '../../../app/app_state.dart';
import '../../management/expenses_page.dart';
import '../../calculator/presentation/calculator_page.dart';
import '../../../models/horse_batch.dart';
import '../../../widgets/app_components.dart';
import 'horse_detail_page.dart';
import 'history_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final now = DateTime.now();
    final today = state.horses.where(
      (horse) =>
          horse.createdAt.year == now.year &&
          horse.createdAt.month == now.month &&
          horse.createdAt.day == now.day,
    );
    final todayHorses = today.toList();
    final totalWeight = todayHorses.fold<double>(
      0,
      (sum, horse) => sum + horse.liveWeightKg,
    );
    final production = todayHorses.fold<double>(
      0,
      (sum, horse) => sum + horse.totalMeasuredKg,
    );

    return pageContent(
      title: 'Adenalin Calculator',
      subtitle: 'Otni qayta ishlash va qazi tarkibini hisobga olish',
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 540 ? 3 : 1;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bugungi ishlab chiqarish',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: columns,
                      childAspectRatio: columns == 1 ? 4.8 : 1.4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        MetricTile(
                          label: 'Qayd etilgan otlar',
                          value: '${todayHorses.length}',
                          icon: Icons.pets_outlined,
                        ),
                        MetricTile(
                          label: 'Tirik vazn',
                          value: formatKg(totalWeight),
                          icon: Icons.monitor_weight_outlined,
                        ),
                        MetricTile(
                          label: 'Real mahsulot',
                          value: formatKg(production),
                          icon: Icons.inventory_2_outlined,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: 'Tezkor amallar',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => pushPage(context, const CalculatorPage()),
                icon: const Icon(Icons.add),
                label: const Text('Yangi qayd'),
              ),
              OutlinedButton.icon(
                onPressed: () => pushPage(context, const HistoryPage()),
                icon: const Icon(Icons.history),
                label: const Text('Tarix'),
              ),
              OutlinedButton.icon(
                onPressed: () => pushPage(context, const ExpensesPage()),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Xarajatlar'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          title: 'So‘nggi qaydlar',
          trailing: TextButton(
            onPressed: () => pushPage(context, const HistoryPage()),
            child: const Text('Barchasi'),
          ),
          child: state.horses.isEmpty
              ? const EmptyState(
                  icon: Icons.pets_outlined,
                  title: 'Hali qaydlar yo‘q',
                  subtitle:
                      'Birinchi o‘lchangan qayta ishlash natijasini kiriting.',
                )
              : Column(
                  children: state.horses
                      .take(5)
                      .map((horse) => _RecentHorseTile(horse: horse))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _RecentHorseTile extends StatelessWidget {
  const _RecentHorseTile({required this.horse});
  final HorseBatch horse;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: const Icon(Icons.pets_outlined),
        ),
        title: Text(horse.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${horse.createdAt.toLocal().toString().substring(0, 16)} · ${formatKg(horse.totalMeasuredKg)}',
        ),
        trailing: Text(
          formatKg(horse.liveWeightKg),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        onTap: () => pushPage(context, HorseDetailPage(horse: horse)),
      );
}
