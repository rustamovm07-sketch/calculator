import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../models/expense.dart';
import '../../widgets/app_components.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  static const _categories = [
    'Ot xaridi',
    'Qayta ishlash',
    'Qadoqlash',
    'Ziravor',
    'Ish haqi',
    'Transport',
    'Elektr',
    'Gaz',
    'Boshqa',
  ];

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  Expense? _editing;
  String? _category;
  int _horseId = 0;

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  double? _parse(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));

  void _edit(Expense item) {
    setState(() {
      _editing = item;
      _category = item.category;
      _horseId = item.horseBatchId;
      _name.text = item.name;
      _amount.text = item.amount.toString();
      _notes.text = item.notes;
    });
  }

  void _clear() {
    setState(() {
      _editing = null;
      _category = null;
      _horseId = 0;
      _name.clear();
      _amount.clear();
      _notes.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      showMessage(context, 'Xarajat kategoriyasini tanlang.');
      return;
    }
    final state = AppScope.of(context);
    final record = _editing ??
        Expense(
          createdAt: DateTime.now(),
          category: _category!,
          name: _name.text.trim(),
          amount: _parse(_amount.text)!,
        );
    record
      ..category = _category!
      ..name = _name.text.trim()
      ..amount = _parse(_amount.text)!
      ..horseBatchId = _horseId
      ..notes = _notes.text.trim();
    try {
      await state.database.saveExpense(record);
      await state.reload();
      if (mounted) {
        _clear();
        showMessage(context, 'Xarajat saqlandi.');
      }
    } catch (error) {
      if (mounted) showMessage(context, 'Saqlab bo‘lmadi: $error');
    }
  }

  Future<void> _delete(Expense item) async {
    final state = AppScope.of(context);
    if (!await confirmAction(
      context,
      title: 'Xarajatni o‘chirish',
      message: 'Tanlangan xarajat o‘chirilsinmi?',
    )) {
      return;
    }
    try {
      await state.database.deleteRecord('expenses', item.id!);
      await state.reload();
      if (mounted && _editing?.id == item.id) _clear();
    } catch (error) {
      if (mounted) showMessage(context, 'O‘chirib bo‘lmadi: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final expenses = state.expenses;
    final now = DateTime.now();
    final today = expenses
        .where(
          (item) =>
              item.createdAt.year == now.year &&
              item.createdAt.month == now.month &&
              item.createdAt.day == now.day,
        )
        .fold<double>(0, (sum, item) => sum + item.amount);
    final month = expenses
        .where(
          (item) =>
              item.createdAt.year == now.year &&
              item.createdAt.month == now.month,
        )
        .fold<double>(0, (sum, item) => sum + item.amount);
    final total = expenses.fold<double>(0, (sum, item) => sum + item.amount);
    return Scaffold(
      appBar: AppBar(title: const Text('Xarajatlar')),
      body: pageContent(
        title: 'Xarajatlar',
        subtitle: 'Barcha sarflarni kuzatib boring',
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 540 ? 3 : 1;
              return GridView.count(
                crossAxisCount: columns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: columns == 1 ? 5 : 1.5,
                children: [
                  MetricTile(
                    label: 'Bugun',
                    value: formatMoney(today),
                    icon: Icons.today_outlined,
                  ),
                  MetricTile(
                    label: 'Bu oy',
                    value: formatMoney(month),
                    icon: Icons.calendar_month_outlined,
                  ),
                  MetricTile(
                    label: 'Jami',
                    value: formatMoney(total),
                    icon: Icons.payments_outlined,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          SectionCard(
            title: _editing == null ? 'Yangi xarajat' : 'Xarajatni tahrirlash',
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Kategoriya'),
                    items: _categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _category = value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Xarajat nomi',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Nom kiriting'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Miqdor',
                      suffixText: 'so‘m',
                    ),
                    validator: (text) {
                      final value = _parse(text ?? '');
                      return value == null || !value.isFinite || value < 0
                          ? 'Noldan kichik bo‘lmagan miqdor kiriting'
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _horseId,
                    decoration: const InputDecoration(
                      labelText: 'Otga bog‘lash (ixtiyoriy)',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 0,
                        child: Text('Umumiy xarajat'),
                      ),
                      ...state.horses.where((horse) => horse.id != null).map(
                            (horse) => DropdownMenuItem(
                              value: horse.id!,
                              child: Text(horse.name),
                            ),
                          ),
                    ],
                    onChanged: (value) => setState(() => _horseId = value ?? 0),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notes,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Izoh (ixtiyoriy)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Saqlash'),
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
            title: 'Saqlangan xarajatlar',
            child: expenses.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'Xarajatlar yo‘q',
                  )
                : Column(
                    children: expenses.map((item) {
                      final linkedHorse = state.horses.where(
                        (horse) => horse.id == item.horseBatchId,
                      );
                      final horseName =
                          linkedHorse.isEmpty ? null : linkedHorse.first.name;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.name),
                        subtitle: Text(
                          '${item.category} · ${item.createdAt.toLocal().toString().substring(0, 10)}${horseName == null ? '' : ' · $horseName'}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formatMoney(item.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) =>
                                  value == 'edit' ? _edit(item) : _delete(item),
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Tahrirlash'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('O‘chirish'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () => _edit(item),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
