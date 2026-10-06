class Expense {
  Expense({
    this.id,
    this.horseBatchId = 0,
    required this.createdAt,
    required this.category,
    required this.name,
    required this.amount,
    this.notes = '',
  });

  int? id;
  int horseBatchId;
  DateTime createdAt;
  String category;
  String name;
  double amount;
  String notes;

  Map<String, Object?> toMap() => {
        'id': id,
        'horseBatchId': horseBatchId,
        'createdAt': createdAt.toIso8601String(),
        'category': category,
        'name': name,
        'amount': amount,
        'notes': notes,
      };

  factory Expense.fromMap(Map<String, Object?> map) {
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

    return Expense(
      id: int.tryParse('${value('id') ?? ''}'),
      horseBatchId: number('horseBatchId').toInt(),
      createdAt:
          DateTime.tryParse('${value('createdAt') ?? ''}') ?? DateTime.now(),
      category: value('category')?.toString() ?? '',
      name: value('name')?.toString() ?? '',
      amount: number('amount'),
      notes: value('notes')?.toString() ?? '',
    );
  }
}
