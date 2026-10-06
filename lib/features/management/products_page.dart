import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../models/product.dart';
import '../../widgets/app_components.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _unit = TextEditingController(text: 'kg');
  final _stock = TextEditingController();
  final _price = TextEditingController();
  final _notes = TextEditingController();
  Product? _editing;
  bool _isActive = true;

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _stock.dispose();
    _price.dispose();
    _notes.dispose();
    super.dispose();
  }

  double? _parse(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  void _edit(Product item) {
    setState(() {
      _editing = item;
      _name.text = item.name;
      _unit.text = item.unit;
      _stock.text = item.stockQuantity.toString();
      _price.text = item.salePrice.toString();
      _notes.text = item.notes;
      _isActive = item.isActive;
    });
  }

  void _clear() {
    setState(() {
      _editing = null;
      _name.clear();
      _unit.text = 'kg';
      _stock.clear();
      _price.clear();
      _notes.clear();
      _isActive = true;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final state = AppScope.of(context);
    final product = _editing ??
        Product(
          name: _name.text.trim(),
          salePrice: _parse(_price.text)!,
          stockQuantity: _parse(_stock.text)!,
          createdAt: DateTime.now(),
        );
    product
      ..name = _name.text.trim()
      ..unit = _unit.text.trim().isEmpty ? 'kg' : _unit.text.trim()
      ..stockQuantity = _parse(_stock.text)!
      ..salePrice = _parse(_price.text)!
      ..isActive = _isActive
      ..notes = _notes.text.trim();
    try {
      await state.database.saveProduct(product);
      await state.reload();
      if (mounted) {
        _clear();
        showMessage(context, 'Mahsulot saqlandi.');
      }
    } catch (error) {
      if (mounted) showMessage(context, 'Saqlab bo‘lmadi: $error');
    }
  }

  Future<void> _delete(Product item) async {
    final state = AppScope.of(context);
    if (!await confirmAction(
      context,
      title: 'Mahsulotni o‘chirish',
      message: 'Tanlangan mahsulot yozuvi o‘chirilsinmi?',
    )) {
      return;
    }
    try {
      await state.database.deleteRecord('products', item.id!);
      await state.reload();
      if (mounted && _editing?.id == item.id) _clear();
    } catch (error) {
      if (mounted) showMessage(context, 'O‘chirib bo‘lmadi: $error');
    }
  }

  String? _validate(String? text) {
    final value = _parse(text ?? '');
    return value == null || !value.isFinite || value < 0
        ? 'Noldan kichik bo‘lmagan son kiriting'
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final products = AppScope.of(context).products;
    return Scaffold(
      appBar: AppBar(title: const Text('Mahsulotlar')),
      body: pageContent(
        title: 'Mahsulotlar',
        subtitle: 'Mahsulotlar va haqiqiy zaxira miqdori',
        children: [
          SectionCard(
            title:
                _editing == null ? 'Mahsulot qaydi' : 'Mahsulotni tahrirlash',
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Mahsulot nomi',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Nom kiriting'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _unit,
                    decoration: const InputDecoration(labelText: 'Birlik'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _stock,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Haqiqiy zaxira',
                    ),
                    validator: _validate,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Sotuv narxi / birlik',
                      suffixText: 'so‘m',
                    ),
                    validator: _validate,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Faol mahsulot'),
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
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
            title: 'Mahsulotlar ro‘yxati',
            child: products.isEmpty
                ? const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'Mahsulotlar hali yo‘q',
                  )
                : Column(
                    children: products
                        .map(
                          (item) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.name),
                            subtitle: Text(
                              '${item.isActive ? 'Faol' : 'Faol emas'} · ${formatMoney(item.salePrice)} / ${item.unit}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${item.stockQuantity} ${item.unit}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (value) => value == 'edit'
                                      ? _edit(item)
                                      : _delete(item),
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
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
