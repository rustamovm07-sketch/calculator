namespace QaziCalculator.Models;

public sealed class DatabaseBackup
{
    public int FormatVersion { get; set; } = 1;

    public string BackupId { get; set; } = Guid.NewGuid().ToString("N");

    public DateTime ExportedAt { get; set; } = DateTime.Now;

    public List<HorseBatch> HorseBatches { get; set; } = [];

    public List<ProcessingResult> ProcessingResults { get; set; } = [];

    public List<QaziComposition> QaziCompositions { get; set; } = [];

    public List<Expense> Expenses { get; set; } = [];

    public List<Product> Products { get; set; } = [];
}

public sealed class BackupReceipt
{
    [SQLite.PrimaryKey]
    public string BackupId { get; set; } = string.Empty;

    public DateTime ImportedAt { get; set; } = DateTime.Now;
}
