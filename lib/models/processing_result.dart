class ProcessingResult {
  ProcessingResult({
    this.id,
    required this.horseBatchId,
    required this.createdAt,
    required this.liveWeightKg,
    this.cleanMeatKg = 0,
    this.fatKg = 0,
    this.boneKg = 0,
    this.tendonKg = 0,
    this.kachalkaKg = 0,
    this.tarashKg = 0,
    this.wasteKg = 0,
    this.qaziKg = 0,
    this.intestineKg = 0,
    this.otherKg = 0,
  });

  int? id;
  int horseBatchId;
  DateTime createdAt;
  double liveWeightKg;
  double cleanMeatKg;
  double fatKg;
  double boneKg;
  double tendonKg;
  double kachalkaKg;
  double tarashKg;
  double wasteKg;
  double qaziKg;
  double intestineKg;
  double otherKg;

  double get totalMeasuredKg =>
      cleanMeatKg + fatKg + boneKg + tendonKg + kachalkaKg + tarashKg + wasteKg;
  double get totalMeasuredPercent =>
      liveWeightKg > 0 ? totalMeasuredKg / liveWeightKg * 100 : 0;
  double get unaccountedWeightKg =>
      (liveWeightKg - totalMeasuredKg).clamp(0, double.infinity);
  double percent(double value) =>
      liveWeightKg > 0 ? value / liveWeightKg * 100 : 0;

  List<(String, double)> get measuredOutputs => [
        ('Toza go‘sht', cleanMeatKg),
        ('Yog‘', fatKg),
        ('Suyak', boneKg),
        ('Pay', tendonKg),
        ('Kachalka', kachalkaKg),
        ('Tarash', tarashKg),
        ('Chiqindi', wasteKg),
      ];

  Map<String, Object?> toMap() => {
        'id': id,
        'horseBatchId': horseBatchId,
        'createdAt': createdAt.toIso8601String(),
        'liveWeightKg': liveWeightKg,
        'cleanMeatKg': cleanMeatKg,
        'fatKg': fatKg,
        'boneKg': boneKg,
        'tendonKg': tendonKg,
        'kachalkaKg': kachalkaKg,
        'tarashKg': tarashKg,
        'wasteKg': wasteKg,
        'qaziKg': qaziKg,
        'intestineKg': intestineKg,
        'otherKg': otherKg,
      };

  factory ProcessingResult.fromMap(Map<String, Object?> map) {
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

    return ProcessingResult(
      id: int.tryParse('${value('id') ?? ''}'),
      horseBatchId: number('horseBatchId').toInt(),
      createdAt:
          DateTime.tryParse('${value('createdAt') ?? ''}') ?? DateTime.now(),
      liveWeightKg: number('liveWeightKg'),
      cleanMeatKg: number('cleanMeatKg'),
      fatKg: number('fatKg'),
      boneKg: number('boneKg'),
      tendonKg: number('tendonKg'),
      kachalkaKg: number('kachalkaKg'),
      tarashKg: number('tarashKg'),
      wasteKg: number('wasteKg'),
      qaziKg: number('qaziKg'),
      intestineKg: number('intestineKg'),
      otherKg: number('otherKg'),
    );
  }
}
