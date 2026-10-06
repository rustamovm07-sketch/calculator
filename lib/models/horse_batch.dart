class HorseBatch {
  HorseBatch({
    this.id,
    required this.name,
    required this.createdAt,
    required this.liveWeightKg,
    this.purchasePricePerKg = 0,
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
    this.notes = '',
  });

  int? id;
  String name;
  DateTime createdAt;
  double liveWeightKg;
  double purchasePricePerKg;
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
  String notes;

  double get totalPurchaseCost => liveWeightKg * purchasePricePerKg;
  double get totalMeasuredKg =>
      measuredOutputs.fold(0, (sum, value) => sum + value.$2);
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
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'liveWeightKg': liveWeightKg,
        'purchasePricePerKg': purchasePricePerKg,
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
        'notes': notes,
      };

  factory HorseBatch.fromMap(Map<String, Object?> map) => HorseBatch(
        id: _integer(map, 'id'),
        name: _string(map, 'name'),
        createdAt: _date(map, 'createdAt'),
        liveWeightKg: _number(map, 'liveWeightKg'),
        purchasePricePerKg: _number(map, 'purchasePricePerKg'),
        cleanMeatKg: _number(map, 'cleanMeatKg'),
        fatKg: _number(map, 'fatKg'),
        boneKg: _number(map, 'boneKg'),
        tendonKg: _number(map, 'tendonKg'),
        kachalkaKg: _number(map, 'kachalkaKg'),
        tarashKg: _number(map, 'tarashKg'),
        wasteKg: _number(map, 'wasteKg'),
        qaziKg: _number(map, 'qaziKg'),
        intestineKg: _number(map, 'intestineKg'),
        otherKg: _number(map, 'otherKg'),
        notes: _string(map, 'notes'),
      );

  static String _string(Map<String, Object?> map, String key) =>
      _value(map, key)?.toString() ?? '';

  static int? _integer(Map<String, Object?> map, String key) {
    final value = _value(map, key);
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  static double _number(Map<String, Object?> map, String key) {
    final value = _value(map, key);
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _date(Map<String, Object?> map, String key) =>
      DateTime.tryParse(_value(map, key)?.toString() ?? '') ?? DateTime.now();

  static Object? _value(Map<String, Object?> map, String key) {
    for (final entry in map.entries) {
      if (entry.key.toLowerCase() == key.toLowerCase()) return entry.value;
    }
    return null;
  }
}
