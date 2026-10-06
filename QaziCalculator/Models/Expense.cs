namespace QaziCalculator.Models;

public class Expense
{
    public int Id { get; set; }

    // Qaysi ot/partiyaga tegishli.
    // 0 bo‘lsa umumiy xarajat hisoblanadi.
    public int HorseBatchId { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.Now;

    // Masalan:
    // Go‘sht
    // Ishchi
    // Ziravor
    // Ichak
    // Qadoqlash
    // Transport
    // Boshqa
    public string Category { get; set; } = string.Empty;

    public string Name { get; set; } = string.Empty;

    public decimal Amount { get; set; }

    public string Notes { get; set; } = string.Empty;
}