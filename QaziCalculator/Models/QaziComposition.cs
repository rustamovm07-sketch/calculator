namespace QaziCalculator.Models;

public class QaziComposition
{
    public int Id { get; set; }

    // Qazi qaysi ot/partiyadan olinganini bog‘laydi.
    public int HorseBatchId { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.Now;

    // Ushbu partiyada ishlab chiqarilgan jami qazi.
    public double TotalQaziKg { get; set; }

    // Qazi tarkibidagi real o‘lchangan toza go‘sht.
    public double MeatKg { get; set; }

    // Qazi tarkibidagi real o‘lchangan yog‘.
    public double FatKg { get; set; }

    // Ixtiyoriy: qazi tayyorlashda ishlatilgan boshqa
    // o‘lchangan tarkiblar uchun izoh.
    public string Notes { get; set; } = string.Empty;

    // 1 kg qazi tarkibidagi go‘sht miqdori.
    public double MeatPerQaziKg =>
        TotalQaziKg > 0
            ? MeatKg / TotalQaziKg
            : 0;

    // 1 kg qazi tarkibidagi yog‘ miqdori.
    public double FatPerQaziKg =>
        TotalQaziKg > 0
            ? FatKg / TotalQaziKg
            : 0;

    // Qazi tarkibidagi go‘sht foizi.
    public double MeatPercent =>
        TotalQaziKg > 0
            ? MeatKg / TotalQaziKg * 100.0
            : 0;

    // Qazi tarkibidagi yog‘ foizi.
    public double FatPercent =>
        TotalQaziKg > 0
            ? FatKg / TotalQaziKg * 100.0
            : 0;

    // O‘lchangan tarkib qazini to‘liq yopmayotgan bo‘lsa,
    // qolgan qismni ko‘rsatadi.
    public double UnaccountedKg =>
        Math.Max(
            0,
            TotalQaziKg - MeatKg - FatKg);

    public double UnaccountedPercent =>
        TotalQaziKg > 0
            ? UnaccountedKg / TotalQaziKg * 100.0
            : 0;
}
