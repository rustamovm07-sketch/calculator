import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../../models/database_backup.dart';
import '../../models/expense.dart';
import '../../models/horse_batch.dart';
import '../../models/processing_result.dart';
import '../../models/product.dart';
import '../../models/qazi_composition.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();
  static const int maxBackupBytes = 50 * 1024 * 1024;

  Future<Database>? _opening;

  Future<Database> get _database => _opening ??= _openDatabase();

  Future<Database> _openDatabase() async {
    final path =
        '${await getDatabasesPath()}${Platform.pathSeparator}adenalin_calculator.db';
    return openDatabase(
      path,
      version: 1,
      onCreate: (database, version) async {
        for (final table in _tables) {
          await database.execute(
            'CREATE TABLE $table (id INTEGER PRIMARY KEY AUTOINCREMENT, data TEXT NOT NULL)',
          );
        }
        await database.execute(
          'CREATE TABLE backup_receipts (backup_id TEXT PRIMARY KEY, imported_at TEXT NOT NULL)',
        );
      },
    );
  }

  static const _tables = [
    'horse_batches',
    'processing_results',
    'qazi_compositions',
    'expenses',
    'products',
  ];

  Future<List<T>> _all<T>(
    String table,
    T Function(Map<String, Object?>) decode,
  ) async {
    final db = await _database;
    final rows = await db.query(table, orderBy: 'id DESC');
    return rows.map((row) {
      final map = jsonDecode(row['data']! as String) as Map<String, dynamic>;
      map['id'] = row['id'];
      return decode(Map<String, Object?>.from(map));
    }).toList();
  }

  Future<List<HorseBatch>> getHorseBatches() =>
      _all('horse_batches', HorseBatch.fromMap);
  Future<List<ProcessingResult>> getProcessingResults() =>
      _all('processing_results', ProcessingResult.fromMap);
  Future<List<QaziComposition>> getQaziCompositions() =>
      _all('qazi_compositions', QaziComposition.fromMap);
  Future<List<Expense>> getExpenses() => _all('expenses', Expense.fromMap);
  Future<List<Product>> getProducts() => _all('products', Product.fromMap);

  Future<int> _save(String table, int? id, Map<String, Object?> map) async {
    final db = await _database;
    final data = Map<String, Object?>.from(map)..remove('id');
    if (id == null) {
      return db.insert(table, {'data': jsonEncode(data)});
    }
    final updated = await db.update(
      table,
      {'data': jsonEncode(data)},
      where: 'id = ?',
      whereArgs: [id],
    );
    if (updated == 0) {
      throw StateError('The record no longer exists.');
    }
    return id;
  }

  Future<void> saveHorseAndResult(
    HorseBatch horse,
    ProcessingResult result,
  ) async {
    if (horse.id != null || result.id != null) {
      throw StateError('Only a new processing record can be saved atomically.');
    }
    final db = await _database;
    try {
      await db.transaction((transaction) async {
        final horseMap = horse.toMap()..remove('id');
        final horseId = await transaction.insert('horse_batches', {
          'data': jsonEncode(horseMap),
        });
        horse.id = horseId;
        result.horseBatchId = horseId;
        result.createdAt = horse.createdAt;
        result.id = await transaction.insert('processing_results', {
          'data': jsonEncode(result.toMap()..remove('id')),
        });
      });
    } catch (_) {
      horse.id = null;
      result
        ..id = null
        ..horseBatchId = 0;
      rethrow;
    }
  }

  Future<int> saveQaziComposition(QaziComposition value) async {
    value.id = await _save('qazi_compositions', value.id, value.toMap());
    return value.id!;
  }

  Future<int> saveExpense(Expense value) async {
    value.id = await _save('expenses', value.id, value.toMap());
    return value.id!;
  }

  Future<int> saveProduct(Product value) async {
    value.id = await _save('products', value.id, value.toMap());
    return value.id!;
  }

  Future<void> deleteHorseBatch(int id) async {
    final db = await _database;
    await db.transaction((transaction) async {
      for (final table in [
        'processing_results',
        'qazi_compositions',
        'expenses',
      ]) {
        final rows = await transaction.query(table);
        for (final row in rows) {
          final data =
              jsonDecode(row['data']! as String) as Map<String, dynamic>;
          if (data['horseBatchId'] == id) {
            await transaction.delete(
              table,
              where: 'id = ?',
              whereArgs: [row['id']],
            );
          }
        }
      }
      await transaction.delete(
        'horse_batches',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> deleteRecord(String table, int id) async {
    if (!_tables.contains(table)) throw ArgumentError.value(table, 'table');
    final db = await _database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<DatabaseBackup> createBackup() async => DatabaseBackup(
        backupId: DateTime.now()
            .microsecondsSinceEpoch
            .toRadixString(16)
            .padLeft(32, '0'),
        exportedAt: DateTime.now(),
        horseBatches: await getHorseBatches(),
        processingResults: await getProcessingResults(),
        qaziCompositions: await getQaziCompositions(),
        expenses: await getExpenses(),
        products: await getProducts(),
      );

  Future<bool> importBackup(DatabaseBackup backup) async {
    if (backup.backupId.length != 32 ||
        int.tryParse(backup.backupId, radix: 16) == null) {
      throw const FormatException('Backup identifier is invalid.');
    }
    if (backup.horseBatches.length > 100000 ||
        backup.processingResults.length > 100000 ||
        backup.qaziCompositions.length > 100000 ||
        backup.expenses.length > 100000 ||
        backup.products.length > 100000) {
      throw const FormatException('Backup contains too many records.');
    }
    final ids = backup.horseBatches.map((horse) => horse.id).toSet();
    if (ids.contains(null) ||
        ids.length != backup.horseBatches.length ||
        backup.horseBatches.any((horse) => horse.id! <= 0)) {
      throw const FormatException('Horse records contain invalid identifiers.');
    }
    final horseIds = ids.cast<int>();
    if (backup.horseBatches.any(
          (horse) =>
              horse.name.trim().isEmpty ||
              !horse.liveWeightKg.isFinite ||
              horse.liveWeightKg <= 0 ||
              !horse.purchasePricePerKg.isFinite ||
              horse.purchasePricePerKg < 0 ||
              horse.measuredOutputs.any(
                (entry) => !entry.$2.isFinite || entry.$2 < 0,
              ) ||
              horse.totalMeasuredKg > horse.liveWeightKg,
        ) ||
        backup.processingResults.any(
          (item) =>
              item.id == null ||
              item.id! <= 0 ||
              !horseIds.contains(item.horseBatchId) ||
              !item.liveWeightKg.isFinite ||
              item.liveWeightKg <= 0 ||
              item.totalMeasuredKg > item.liveWeightKg ||
              item.measuredOutputs.any(
                (entry) => !entry.$2.isFinite || entry.$2 < 0,
              ),
        ) ||
        backup.qaziCompositions.any(
          (item) =>
              item.id == null ||
              item.id! <= 0 ||
              !horseIds.contains(item.horseBatchId) ||
              !item.totalQaziKg.isFinite ||
              item.totalQaziKg <= 0 ||
              !item.meatKg.isFinite ||
              !item.fatKg.isFinite ||
              item.meatKg < 0 ||
              item.fatKg < 0 ||
              item.meatKg + item.fatKg > item.totalQaziKg,
        ) ||
        backup.expenses.any(
          (item) =>
              item.id == null ||
              item.id! <= 0 ||
              (item.horseBatchId != 0 &&
                  !horseIds.contains(item.horseBatchId)) ||
              item.name.trim().isEmpty ||
              !item.amount.isFinite ||
              item.amount < 0,
        ) ||
        backup.products.any(
          (item) =>
              item.id == null ||
              item.id! <= 0 ||
              item.name.trim().isEmpty ||
              !item.stockQuantity.isFinite ||
              item.stockQuantity < 0 ||
              !item.salePrice.isFinite ||
              item.salePrice < 0,
        )) {
      throw const FormatException(
        'Backup contains invalid records or references.',
      );
    }

    final db = await _database;
    final existing = await db.query(
      'backup_receipts',
      where: 'backup_id = ?',
      whereArgs: [backup.backupId],
      limit: 1,
    );
    if (existing.isNotEmpty) return false;

    await db.transaction((transaction) async {
      final remappedIds = <int, int>{};
      for (final horse in backup.horseBatches) {
        final originalId = horse.id!;
        horse.id = null;
        final id = await transaction.insert('horse_batches', {
          'data': jsonEncode(horse.toMap()..remove('id')),
        });
        remappedIds[originalId] = id;
      }
      for (final item in backup.processingResults) {
        item.id = null;
        item.horseBatchId = remappedIds[item.horseBatchId]!;
        await transaction.insert('processing_results', {
          'data': jsonEncode(item.toMap()..remove('id')),
        });
      }
      for (final item in backup.qaziCompositions) {
        item.id = null;
        item.horseBatchId = remappedIds[item.horseBatchId]!;
        await transaction.insert('qazi_compositions', {
          'data': jsonEncode(item.toMap()..remove('id')),
        });
      }
      for (final item in backup.expenses) {
        item.id = null;
        if (item.horseBatchId != 0) {
          item.horseBatchId = remappedIds[item.horseBatchId]!;
        }
        await transaction.insert('expenses', {
          'data': jsonEncode(item.toMap()..remove('id')),
        });
      }
      for (final item in backup.products) {
        item.id = null;
        await transaction.insert('products', {
          'data': jsonEncode(item.toMap()..remove('id')),
        });
      }
      await transaction.insert('backup_receipts', {
        'backup_id': backup.backupId,
        'imported_at': DateTime.now().toIso8601String(),
      });
    });
    return true;
  }

  Future<int> deleteAllData() async {
    final db = await _database;
    return db.transaction((transaction) async {
      var deleted = 0;
      for (final table in [..._tables.reversed, 'backup_receipts']) {
        deleted += await transaction.delete(table);
      }
      return deleted;
    });
  }

  Future<(int, int, int, int, int)> getRecordCounts() async {
    final db = await _database;
    final counts = <int>[];
    for (final table in _tables) {
      counts.add(
        await db
            .rawQuery('SELECT COUNT(*) AS count FROM $table')
            .then((rows) => rows.first['count']! as int),
      );
    }
    return (counts[0], counts[1], counts[2], counts[3], counts[4]);
  }

  Future<int> getDatabaseSize() async {
    final path = await getDatabasesPath();
    final file = File('$path${Platform.pathSeparator}adenalin_calculator.db');
    if (await file.exists()) {
      return file.length();
    }
    return 0;
  }
}
