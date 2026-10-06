using System.Text.Json;
using QaziCalculator.Data;
using QaziCalculator.Models;

namespace QaziCalculator.Services;

public sealed class BackupService(DatabaseService databaseService)
{
    private const int MaximumBackupBytes = 50 * 1024 * 1024;
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        WriteIndented = true,
        MaxDepth = 32
    };

    public async Task<string> CreateBackupAsync()
    {
        var backup = new DatabaseBackup
        {
            HorseBatches = await databaseService.GetHorseBatchesAsync(),
            ProcessingResults = await databaseService.GetAllProcessingResultsAsync(),
            QaziCompositions = await databaseService.GetQaziCompositionsAsync(),
            Expenses = await databaseService.GetExpensesAsync(),
            Products = await databaseService.GetProductsAsync()
        };

        var filePath = Path.Combine(
            FileSystem.CacheDirectory,
            $"QaziCalculator-backup-{DateTime.Now:yyyyMMdd-HHmmss}.json");

        await using var stream = File.Create(filePath);
        await JsonSerializer.SerializeAsync(stream, backup, JsonOptions);
        await stream.FlushAsync();
        return filePath;
    }

    public async Task<bool> ImportBackupAsync(FileResult backupFile)
    {
        await using var stream = await backupFile.OpenReadAsync();

        if (stream.CanSeek && stream.Length > MaximumBackupBytes)
            throw new InvalidDataException("Zaxira fayli hajmi ruxsat etilgan chegaradan katta.");

        await using var boundedStream = await ReadBoundedAsync(stream);
        var backup = await JsonSerializer.DeserializeAsync<DatabaseBackup>(
            boundedStream,
            JsonOptions);

        if (backup is null)
            throw new InvalidDataException("Zaxira fayli bo'sh yoki buzilgan.");

        ValidateBackup(backup);
        return await databaseService.ImportBackupAsync(backup);
    }

    private static async Task<MemoryStream> ReadBoundedAsync(Stream source)
    {
        var copy = new MemoryStream();
        var buffer = new byte[81920];
        int bytesRead;

        while ((bytesRead = await source.ReadAsync(buffer)) > 0)
        {
            if (copy.Length + bytesRead > MaximumBackupBytes)
                throw new InvalidDataException("Zaxira fayli hajmi ruxsat etilgan chegaradan katta.");

            await copy.WriteAsync(buffer.AsMemory(0, bytesRead));
        }

        copy.Position = 0;
        return copy;
    }

    private static void ValidateBackup(DatabaseBackup backup)
    {
        if (backup.FormatVersion != 1 ||
            !Guid.TryParseExact(backup.BackupId, "N", out _) ||
            backup.HorseBatches is null ||
            backup.ProcessingResults is null ||
            backup.QaziCompositions is null ||
            backup.Expenses is null ||
            backup.Products is null)
        {
            throw new InvalidDataException("Zaxira faylining formati qo'llab-quvvatlanmaydi.");
        }

        if (backup.HorseBatches.Count > 100_000 ||
            backup.ProcessingResults.Count > 100_000 ||
            backup.QaziCompositions.Count > 100_000 ||
            backup.Expenses.Count > 100_000 ||
            backup.Products.Count > 100_000)
        {
            throw new InvalidDataException("Zaxira faylida juda ko'p yozuv bor.");
        }

        var batchIds = backup.HorseBatches.Select(x => x.Id).ToHashSet();
        if (batchIds.Count != backup.HorseBatches.Count ||
            backup.HorseBatches.Any(x =>
                x.Id <= 0 ||
                string.IsNullOrWhiteSpace(x.Name) ||
                !IsFinitePositive(x.LiveWeightKg) ||
                x.PurchasePricePerKg < 0 ||
                !IsValidMeasuredOutput(x.CleanMeatKg, x.FatKg, x.BoneKg, x.TendonKg, x.KachalkaKg, x.TarashKg, x.WasteKg, x.LiveWeightKg)))
        {
            throw new InvalidDataException("Zaxira faylida ot ma'lumotlari noto'g'ri.");
        }

        if (backup.ProcessingResults.Any(x =>
                x.Id <= 0 ||
                !batchIds.Contains(x.HorseBatchId) ||
                !IsFinitePositive(x.LiveWeightKg) ||
                !IsValidMeasuredOutput(x.CleanMeatKg, x.FatKg, x.BoneKg, x.TendonKg, x.KachalkaKg, x.TarashKg, x.WasteKg, x.LiveWeightKg)) ||
            backup.QaziCompositions.Any(x =>
                x.Id <= 0 ||
                !batchIds.Contains(x.HorseBatchId) ||
                !IsFinitePositive(x.TotalQaziKg) ||
                !IsFiniteNonNegative(x.MeatKg) ||
                !IsFiniteNonNegative(x.FatKg) ||
                x.MeatKg + x.FatKg > x.TotalQaziKg) ||
            backup.Expenses.Any(x =>
                x.Id <= 0 ||
                (x.HorseBatchId != 0 && !batchIds.Contains(x.HorseBatchId)) ||
                string.IsNullOrWhiteSpace(x.Name) ||
                x.Amount < 0) ||
            backup.Products.Any(x =>
                x.Id <= 0 ||
                string.IsNullOrWhiteSpace(x.Name) ||
                x.SalePrice < 0 ||
                !IsFiniteNonNegative(x.StockQuantity)))
        {
            throw new InvalidDataException("Zaxira faylida bog'langan yoki moliyaviy ma'lumotlar noto'g'ri.");
        }
    }

    private static bool IsValidMeasuredOutput(
        double cleanMeatKg,
        double fatKg,
        double boneKg,
        double tendonKg,
        double kachalkaKg,
        double tarashKg,
        double wasteKg,
        double liveWeightKg)
    {
        var values = new[]
        {
            cleanMeatKg, fatKg, boneKg, tendonKg,
            kachalkaKg, tarashKg, wasteKg
        };

        return values.All(IsFiniteNonNegative) &&
            values.Sum() <= liveWeightKg;
    }

    private static bool IsFinitePositive(double value) =>
        value > 0 && double.IsFinite(value);

    private static bool IsFiniteNonNegative(double value) =>
        value >= 0 && double.IsFinite(value);
}
