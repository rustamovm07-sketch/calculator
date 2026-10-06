using SQLite;
using QaziCalculator.Models;

namespace QaziCalculator.Data;

public class DatabaseService
{
    private SQLiteAsyncConnection? _database;

    private async Task InitAsync()
    {
        if (_database is not null)
            return;

        var databasePath = Path.Combine(
            FileSystem.AppDataDirectory,
            "QaziCalculator.db3");

        _database = new SQLiteAsyncConnection(databasePath);

        await _database.CreateTableAsync<HorseBatch>();
        await _database.CreateTableAsync<ProcessingResult>();
        await _database.CreateTableAsync<Expense>();
        await _database.CreateTableAsync<Product>();
        await _database.CreateTableAsync<QaziComposition>();
        await _database.CreateTableAsync<BackupReceipt>();

        await RunMigrationsAsync();
    }

    private async Task RunMigrationsAsync()
    {
        if (_database is null)
            return;

        await AddColumnIfMissingAsync(
            "HorseBatch",
            "CleanMeatKg",
            "REAL NOT NULL DEFAULT 0");

        await AddColumnIfMissingAsync(
            "HorseBatch",
            "QaziKg",
            "REAL NOT NULL DEFAULT 0");

        await AddColumnIfMissingAsync(
            "ProcessingResult",
            "CleanMeatKg",
            "REAL NOT NULL DEFAULT 0");

        await AddColumnIfMissingAsync(
            "ProcessingResult",
            "QaziKg",
            "REAL NOT NULL DEFAULT 0");
    }

    private async Task AddColumnIfMissingAsync(
        string tableName,
        string columnName,
        string columnDefinition)
    {
        if (_database is null)
            return;

        var tableInfo =
            await _database.GetTableInfoAsync(tableName);

        var exists =
            tableInfo.Any(x =>
                string.Equals(
                    x.Name,
                    columnName,
                    StringComparison.OrdinalIgnoreCase));

        if (exists)
            return;

        await _database.ExecuteAsync(
            $"ALTER TABLE {tableName} " +
            $"ADD COLUMN {columnName} {columnDefinition}");
    }

    public async Task<List<HorseBatch>> GetHorseBatchesAsync()
    {
        await InitAsync();

        return await _database!
            .Table<HorseBatch>()
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();
    }

    public async Task<HorseBatch?> GetHorseBatchAsync(int id)
    {
        await InitAsync();

        return await _database!
            .Table<HorseBatch>()
            .Where(x => x.Id == id)
            .FirstOrDefaultAsync();
    }

    public async Task<int> SaveHorseBatchAsync(
        HorseBatch batch)
    {
        await InitAsync();

        if (batch.Id == 0)
            return await _database!.InsertAsync(batch);

        return await _database!.UpdateAsync(batch);
    }

    public async Task SaveHorseBatchAndProcessingResultAsync(
        HorseBatch batch,
        ProcessingResult result)
    {
        await InitAsync();

        if (batch.Id != 0 || result.Id != 0)
            throw new InvalidOperationException("Faqat yangi qayta ishlash natijasini atomar saqlash mumkin.");

        try
        {
            await _database!.RunInTransactionAsync(connection =>
            {
                connection.Insert(batch);
                result.HorseBatchId = batch.Id;
                result.CreatedAt = batch.CreatedAt;
                connection.Insert(result);
            });
        }
        catch
        {
            batch.Id = 0;
            result.Id = 0;
            result.HorseBatchId = 0;
            throw;
        }
    }

    public async Task<int> DeleteHorseBatchAsync(
        HorseBatch batch)
    {
        await InitAsync();

        await _database!
            .Table<QaziComposition>()
            .Where(x => x.HorseBatchId == batch.Id)
            .DeleteAsync();

        await _database!
            .Table<ProcessingResult>()
            .Where(x => x.HorseBatchId == batch.Id)
            .DeleteAsync();

        await _database!
            .Table<Expense>()
            .Where(x => x.HorseBatchId == batch.Id)
            .DeleteAsync();

        return await _database!.DeleteAsync(batch);
    }

    public async Task<List<ProcessingResult>>
        GetProcessingResultsAsync(int horseBatchId)
    {
        await InitAsync();

        return await _database!
            .Table<ProcessingResult>()
            .Where(x => x.HorseBatchId == horseBatchId)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();
    }

    public async Task<List<ProcessingResult>>
        GetAllProcessingResultsAsync()
    {
        await InitAsync();

        return await _database!
            .Table<ProcessingResult>()
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();
    }

    public async Task<ProcessingResult?>
        GetProcessingResultAsync(int id)
    {
        await InitAsync();

        return await _database!
            .Table<ProcessingResult>()
            .Where(x => x.Id == id)
            .FirstOrDefaultAsync();
    }

    public async Task<int> SaveProcessingResultAsync(
        ProcessingResult result)
    {
        await InitAsync();

        if (result.Id == 0)
            return await _database!.InsertAsync(result);

        return await _database!.UpdateAsync(result);
    }

    public async Task<int> DeleteProcessingResultAsync(
        ProcessingResult result)
    {
        await InitAsync();

        return await _database!.DeleteAsync(result);
    }

    public async Task<List<QaziComposition>>
        GetQaziCompositionsAsync(int? horseBatchId = null)
    {
        await InitAsync();

        if (horseBatchId.HasValue)
        {
            return await _database!
                .Table<QaziComposition>()
                .Where(x =>
                    x.HorseBatchId ==
                    horseBatchId.Value)
                .OrderByDescending(x => x.CreatedAt)
                .ToListAsync();
        }

        return await _database!
            .Table<QaziComposition>()
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();
    }

    public async Task<QaziComposition?>
        GetQaziCompositionAsync(int id)
    {
        await InitAsync();

        return await _database!
            .Table<QaziComposition>()
            .Where(x => x.Id == id)
            .FirstOrDefaultAsync();
    }

    public async Task<int> SaveQaziCompositionAsync(
        QaziComposition composition)
    {
        await InitAsync();

        if (composition.Id == 0)
            return await _database!
                .InsertAsync(composition);

        return await _database!
            .UpdateAsync(composition);
    }

    public async Task<int> DeleteQaziCompositionAsync(
        QaziComposition composition)
    {
        await InitAsync();

        return await _database!
            .DeleteAsync(composition);
    }

    public async Task<List<Expense>> GetExpensesAsync(
        int? horseBatchId = null)
    {
        await InitAsync();

        if (horseBatchId.HasValue)
        {
            return await _database!
                .Table<Expense>()
                .Where(x =>
                    x.HorseBatchId ==
                    horseBatchId.Value)
                .OrderByDescending(x => x.CreatedAt)
                .ToListAsync();
        }

        return await _database!
            .Table<Expense>()
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync();
    }

    public async Task<int> SaveExpenseAsync(
        Expense expense)
    {
        await InitAsync();

        if (expense.Id == 0)
            return await _database!.InsertAsync(expense);

        return await _database!.UpdateAsync(expense);
    }

    public async Task<int> DeleteExpenseAsync(
        Expense expense)
    {
        await InitAsync();

        return await _database!
            .DeleteAsync(expense);
    }

    public async Task<List<Product>> GetProductsAsync()
    {
        await InitAsync();

        return await _database!
            .Table<Product>()
            .OrderBy(x => x.Name)
            .ToListAsync();
    }

    public async Task<Product?> GetProductAsync(int id)
    {
        await InitAsync();

        return await _database!
            .Table<Product>()
            .Where(x => x.Id == id)
            .FirstOrDefaultAsync();
    }

    public async Task<int> SaveProductAsync(
        Product product)
    {
        await InitAsync();

        if (product.Id == 0)
            return await _database!.InsertAsync(product);

        return await _database!.UpdateAsync(product);
    }

    public async Task<int> DeleteProductAsync(
        Product product)
    {
        await InitAsync();

        return await _database!
            .DeleteAsync(product);
    }

    public async Task<bool> ImportBackupAsync(DatabaseBackup backup)
    {
        await InitAsync();

        if (backup.FormatVersion != 1 ||
            !Guid.TryParseExact(backup.BackupId, "N", out _))
        {
            throw new InvalidDataException("Zaxira faylining formati noto'g'ri.");
        }

        var currentReceipt = await _database!
            .FindAsync<BackupReceipt>(backup.BackupId);

        if (currentReceipt is not null)
            return false;

        var horseIds = backup.HorseBatches
            .Select(x => x.Id)
            .ToHashSet();

        if (backup.ProcessingResults.Any(x => !horseIds.Contains(x.HorseBatchId)) ||
            backup.QaziCompositions.Any(x => !horseIds.Contains(x.HorseBatchId)) ||
            backup.Expenses.Any(x => x.HorseBatchId != 0 && !horseIds.Contains(x.HorseBatchId)))
        {
            throw new InvalidDataException("Zaxira faylida noto'g'ri bog'lanishlar mavjud.");
        }

        var batchIdMap = new Dictionary<int, int>();
        await _database.RunInTransactionAsync(connection =>
        {
            foreach (var source in backup.HorseBatches)
            {
                var batch = CopyHorseBatch(source);
                var originalId = source.Id;
                batch.Id = 0;
                connection.Insert(batch);
                batchIdMap.Add(originalId, batch.Id);
            }

            foreach (var source in backup.ProcessingResults)
            {
                var result = CopyProcessingResult(source);
                result.Id = 0;
                result.HorseBatchId = batchIdMap[source.HorseBatchId];
                connection.Insert(result);
            }

            foreach (var source in backup.QaziCompositions)
            {
                var composition = CopyQaziComposition(source);
                composition.Id = 0;
                composition.HorseBatchId = batchIdMap[source.HorseBatchId];
                connection.Insert(composition);
            }

            foreach (var source in backup.Expenses)
            {
                var expense = CopyExpense(source);
                expense.Id = 0;
                expense.HorseBatchId = source.HorseBatchId == 0
                    ? 0
                    : batchIdMap[source.HorseBatchId];
                connection.Insert(expense);
            }

            foreach (var source in backup.Products)
            {
                var product = CopyProduct(source);
                product.Id = 0;
                connection.Insert(product);
            }

            connection.Insert(new BackupReceipt
            {
                BackupId = backup.BackupId,
                ImportedAt = DateTime.Now
            });
        });

        return true;
    }

    public async Task<(
        int HorseCount,
        int ProcessingCount,
        int QaziCompositionCount,
        int ExpenseCount,
        int ProductCount)> GetRecordCountsAsync()
    {
        await InitAsync();
        return (
            await _database!.Table<HorseBatch>().CountAsync(),
            await _database.Table<ProcessingResult>().CountAsync(),
            await _database.Table<QaziComposition>().CountAsync(),
            await _database.Table<Expense>().CountAsync(),
            await _database.Table<Product>().CountAsync());
    }

    public async Task<long> GetDatabaseSizeBytesAsync()
    {
        await InitAsync();
        var databasePath = Path.Combine(
            FileSystem.AppDataDirectory,
            "QaziCalculator.db3");
        return File.Exists(databasePath)
            ? new FileInfo(databasePath).Length
            : 0;
    }

    public async Task<int> DeleteAllDataAsync()
    {
        await InitAsync();
        var deleted = 0;

        await _database!.RunInTransactionAsync(connection =>
        {
            deleted += connection.DeleteAll<QaziComposition>();
            deleted += connection.DeleteAll<ProcessingResult>();
            deleted += connection.DeleteAll<Expense>();
            deleted += connection.DeleteAll<Product>();
            deleted += connection.DeleteAll<HorseBatch>();
            deleted += connection.DeleteAll<BackupReceipt>();
        });

        return deleted;
    }

    private static HorseBatch CopyHorseBatch(HorseBatch source) =>
        new()
        {
            Name = source.Name,
            CreatedAt = source.CreatedAt,
            LiveWeightKg = source.LiveWeightKg,
            PurchasePricePerKg = source.PurchasePricePerKg,
            CleanMeatKg = source.CleanMeatKg,
            FatKg = source.FatKg,
            BoneKg = source.BoneKg,
            TendonKg = source.TendonKg,
            KachalkaKg = source.KachalkaKg,
            TarashKg = source.TarashKg,
            WasteKg = source.WasteKg,
            QaziKg = source.QaziKg,
            IntestineKg = source.IntestineKg,
            OtherKg = source.OtherKg,
            Notes = source.Notes
        };

    private static ProcessingResult CopyProcessingResult(ProcessingResult source) =>
        new()
        {
            HorseBatchId = source.HorseBatchId,
            CreatedAt = source.CreatedAt,
            LiveWeightKg = source.LiveWeightKg,
            CleanMeatKg = source.CleanMeatKg,
            FatKg = source.FatKg,
            BoneKg = source.BoneKg,
            TendonKg = source.TendonKg,
            KachalkaKg = source.KachalkaKg,
            TarashKg = source.TarashKg,
            WasteKg = source.WasteKg,
            QaziKg = source.QaziKg,
            IntestineKg = source.IntestineKg,
            OtherKg = source.OtherKg
        };

    private static QaziComposition CopyQaziComposition(QaziComposition source) =>
        new()
        {
            HorseBatchId = source.HorseBatchId,
            CreatedAt = source.CreatedAt,
            TotalQaziKg = source.TotalQaziKg,
            MeatKg = source.MeatKg,
            FatKg = source.FatKg,
            Notes = source.Notes
        };

    private static Expense CopyExpense(Expense source) =>
        new()
        {
            HorseBatchId = source.HorseBatchId,
            CreatedAt = source.CreatedAt,
            Category = source.Category,
            Name = source.Name,
            Amount = source.Amount,
            Notes = source.Notes
        };

    private static Product CopyProduct(Product source) =>
        new()
        {
            Name = source.Name,
            Unit = source.Unit,
            SalePrice = source.SalePrice,
            StockQuantity = source.StockQuantity,
            IsActive = source.IsActive,
            CreatedAt = source.CreatedAt,
            Notes = source.Notes
        };
}
