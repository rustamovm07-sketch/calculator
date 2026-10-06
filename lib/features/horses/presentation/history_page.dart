import 'package:flutter/material.dart';

import '../../../app/app_state.dart';
import '../../../models/horse_batch.dart';
import '../../../widgets/app_components.dart';
import 'horse_detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final horses = state.horses
        .where(
          (horse) => horse.name.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return pageContent(
      title: 'Tarix',
      subtitle: 'Saqlangan otlar va haqiqiy o‘lchovlar',
      children: [
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value.trim()),
          decoration: InputDecoration(
            hintText: 'Ot nomi bo‘yicha qidirish',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 14),
        SectionCard(
          title: '${horses.length} ta qayd',
          trailing: IconButton(
            tooltip: 'Yangilash',
            onPressed: state.reload,
            icon: const Icon(Icons.refresh),
          ),
          child: horses.isEmpty
              ? EmptyState(
                  icon: _query.isEmpty ? Icons.history : Icons.search_off,
                  title: _query.isEmpty
                      ? 'Hali saqlangan otlar yo‘q'
                      : 'Qidiruv bo‘yicha natija topilmadi',
                  subtitle: _query.isEmpty
                      ? 'Birinchi o‘lchov natijasini saqlang.'
                      : 'Boshqa nom bilan qidirib ko‘ring.',
                )
              : RefreshIndicator(
                  onRefresh: state.reload,
                  child: ListView.separated(
                    itemCount: horses.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        _HorseRow(horse: horses[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

class _HorseRow extends StatelessWidget {
  const _HorseRow({required this.horse});
  final HorseBatch horse;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        leading: CircleAvatar(child: Text('${horse.id ?? '—'}')),
        title: Text(horse.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${horse.createdAt.toLocal().toString().substring(0, 16)}\n'
          'Go‘sht ${formatKg(horse.cleanMeatKg)} · jami ${formatKg(horse.totalMeasuredKg)}',
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatKg(horse.liveWeightKg),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text(
              '${horse.totalMeasuredPercent.toStringAsFixed(1)}% o‘lchangan',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (context) => HorseDetailPage(horse: horse),
          ),
        ),
      );
}
