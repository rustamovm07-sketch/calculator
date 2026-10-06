import 'package:adenalin_calculator/models/database_backup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the existing version-one PascalCase backup format', () {
    final backup = DatabaseBackup.fromMap({
      'FormatVersion': 1,
      'BackupId': '0123456789abcdef0123456789abcdef',
      'ExportedAt': '2026-10-06T12:00:00Z',
      'HorseBatches': [
        {
          'Id': 11,
          'Name': 'Ot-011',
          'CreatedAt': '2026-10-01T08:00:00Z',
          'LiveWeightKg': 420,
          'PurchasePricePerKg': 105000,
          'CleanMeatKg': 120,
          'FatKg': 30,
          'BoneKg': 80,
          'TendonKg': 8,
          'KachalkaKg': 5,
          'TarashKg': 3,
          'WasteKg': 12,
          'QaziKg': 0,
          'IntestineKg': 0,
          'OtherKg': 0,
          'Notes': 'Real o‘lchov',
        },
      ],
      'ProcessingResults': [
        {
          'Id': 21,
          'HorseBatchId': 11,
          'CreatedAt': '2026-10-01T08:00:00Z',
          'LiveWeightKg': 420,
          'CleanMeatKg': 120,
          'FatKg': 30,
          'BoneKg': 80,
          'TendonKg': 8,
          'KachalkaKg': 5,
          'TarashKg': 3,
          'WasteKg': 12,
          'QaziKg': 0,
          'IntestineKg': 0,
          'OtherKg': 0,
        },
      ],
      'QaziCompositions': [
        {
          'Id': 31,
          'HorseBatchId': 11,
          'CreatedAt': '2026-10-01T09:00:00Z',
          'TotalQaziKg': 10,
          'MeatKg': 5,
          'FatKg': 3,
          'Notes': 'Tarkib kuzatuvi',
        },
      ],
      'Expenses': [
        {
          'Id': 41,
          'HorseBatchId': 11,
          'CreatedAt': '2026-10-01T10:00:00Z',
          'Category': 'Transport',
          'Name': 'Yetkazish',
          'Amount': 12000,
          'Notes': '',
        },
      ],
      'Products': [
        {
          'Id': 51,
          'Name': 'Go‘sht',
          'Unit': 'kg',
          'SalePrice': 130000,
          'StockQuantity': 20,
          'IsActive': true,
          'CreatedAt': '2026-10-01T11:00:00Z',
          'Notes': '',
        },
      ],
    });

    expect(backup.backupId, '0123456789abcdef0123456789abcdef');
    expect(backup.horseBatches.single.name, 'Ot-011');
    expect(backup.horseBatches.single.totalMeasuredKg, 258);
    expect(backup.processingResults.single.horseBatchId, 11);
    expect(backup.qaziCompositions.single.meatPerQaziKg, .5);
    expect(backup.expenses.single.amount, 12000);
    expect(backup.products.single.isActive, isTrue);
  });

  test('rejects unsupported backup versions', () {
    expect(
      () => DatabaseBackup.fromMap({
        'FormatVersion': 2,
        'BackupId': '0123456789abcdef0123456789abcdef',
      }),
      throwsFormatException,
    );
  });
}
