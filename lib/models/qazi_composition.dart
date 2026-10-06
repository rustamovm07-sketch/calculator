class QaziComposition {
  QaziComposition({
    this.id,
    required this.horseBatchId,
    required this.createdAt,
    required this.totalQaziKg,
    required this.meatKg,
    required this.fatKg,
    this.notes = '',
  });

  int? id;
  int horseBatchId;
  DateTime createdAt;
  double totalQaziKg;
  double meatKg;
  double fatKg;
  String notes;

  double get meatPerQaziKg => totalQaziKg > 0 ? meatKg / totalQaziKg : 0;
  double get fatPerQaziKg => totalQaziKg > 0 ? fatKg / totalQaziKg : 0;
  double get meatPercent => meatPerQaziKg * 100;
  double get fatPercent => fatPerQaziKg * 100;
  double get unaccountedKg =>
      (totalQaziKg - meatKg - fatKg).clamp(0, double.infinity);

  Map<String, Object?> toMap() => {
        'id': id,
        'horseBatchId': horseBatchId,
        'createdAt': createdAt.toIso8601String(),
        'totalQaziKg': totalQaziKg,
        'meatKg': meatKg,
        'fatKg': fatKg,
        'notes': notes,
      };

  factory QaziComposition.fromMap(Map<String, Object?> map) {
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

    return QaziComposition(
      id: int.tryParse('${value('id') ?? ''}'),
      horseBatchId: number('horseBatchId').toInt(),
      createdAt:
          DateTime.tryParse('${value('createdAt') ?? ''}') ?? DateTime.now(),
      totalQaziKg: number('totalQaziKg'),
      meatKg: number('meatKg'),
      fatKg: number('fatKg'),
      notes: value('notes')?.toString() ?? '',
    );
  }
}
