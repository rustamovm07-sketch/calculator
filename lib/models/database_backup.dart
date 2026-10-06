import 'expense.dart';
import 'horse_batch.dart';
import 'processing_result.dart';
import 'product.dart';
import 'qazi_composition.dart';

class DatabaseBackup {
  DatabaseBackup({
    required this.backupId,
    required this.exportedAt,
    required this.horseBatches,
    required this.processingResults,
    required this.qaziCompositions,
    required this.expenses,
    required this.products,
  });

  final String backupId;
  final DateTime exportedAt;
  final List<HorseBatch> horseBatches;
  final List<ProcessingResult> processingResults;
  final List<QaziComposition> qaziCompositions;
  final List<Expense> expenses;
  final List<Product> products;

  Map<String, Object?> toMap() => {
        'formatVersion': 1,
        'backupId': backupId,
        'exportedAt': exportedAt.toIso8601String(),
        'horseBatches': horseBatches.map((item) => item.toMap()).toList(),
        'processingResults':
            processingResults.map((item) => item.toMap()).toList(),
        'qaziCompositions':
            qaziCompositions.map((item) => item.toMap()).toList(),
        'expenses': expenses.map((item) => item.toMap()).toList(),
        'products': products.map((item) => item.toMap()).toList(),
      };

  factory DatabaseBackup.fromMap(Map<String, dynamic> map) {
    Object? value(String key) {
      for (final entry in map.entries) {
        if (entry.key.toLowerCase() == key.toLowerCase()) return entry.value;
      }
      return null;
    }

    List<T> list<T>(String key, T Function(Map<String, Object?>) decode) {
      final raw = value(key);
      if (raw is! List) {
        throw const FormatException('Backup collection is missing.');
      }
      return raw.map((item) {
        if (item is! Map) throw const FormatException('Invalid backup record.');
        return decode(Map<String, Object?>.from(item));
      }).toList();
    }

    if (value('formatVersion') != 1 || value('backupId') is! String) {
      throw const FormatException('Unsupported backup format.');
    }
    final exportedAt = DateTime.tryParse('${value('exportedAt') ?? ''}');
    if (exportedAt == null) {
      throw const FormatException('Backup export date is invalid.');
    }
    return DatabaseBackup(
      backupId: value('backupId')! as String,
      exportedAt: exportedAt,
      horseBatches: list('horseBatches', HorseBatch.fromMap),
      processingResults: list('processingResults', ProcessingResult.fromMap),
      qaziCompositions: list('qaziCompositions', QaziComposition.fromMap),
      expenses: list('expenses', Expense.fromMap),
      products: list('products', Product.fromMap),
    );
  }
}
