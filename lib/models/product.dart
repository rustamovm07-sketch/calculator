class Product {
  Product({
    this.id,
    required this.name,
    this.unit = 'kg',
    required this.salePrice,
    required this.stockQuantity,
    this.isActive = true,
    required this.createdAt,
    this.notes = '',
  });

  int? id;
  String name;
  String unit;
  double salePrice;
  double stockQuantity;
  bool isActive;
  DateTime createdAt;
  String notes;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'unit': unit,
        'salePrice': salePrice,
        'stockQuantity': stockQuantity,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'notes': notes,
      };

  factory Product.fromMap(Map<String, Object?> map) {
    Object? value(String key) {
      for (final entry in map.entries) {
        if (entry.key.toLowerCase() == key.toLowerCase()) return entry.value;
      }
      return null;
    }

    double number(String key) {
      final raw = value(key);
      return raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 0;
    }

    final activeValue = value('isActive');
    return Product(
      id: int.tryParse('${value('id') ?? ''}'),
      name: value('name')?.toString() ?? '',
      unit: value('unit')?.toString() ?? 'kg',
      salePrice: number('salePrice'),
      stockQuantity: number('stockQuantity'),
      isActive: activeValue == null ||
          activeValue == true ||
          activeValue.toString() == '1',
      createdAt:
          DateTime.tryParse('${value('createdAt') ?? ''}') ?? DateTime.now(),
      notes: value('notes')?.toString() ?? '',
    );
  }
}
