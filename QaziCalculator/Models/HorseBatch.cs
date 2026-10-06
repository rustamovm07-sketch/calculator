namespace QaziCalculator.Models;

public class HorseBatch
{
    public int Id { get; set; }

    public string Name { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.Now;

    // Otning tirik vazni
    public double LiveWeightKg { get; set; }

    // 1 kg uchun xarid narxi
    public decimal PurchasePricePerKg { get; set; }

    // Real qayta ishlash natijalari
    public double CleanMeatKg { get; set; }

    public double FatKg { get; set; }

    public double BoneKg { get; set; }

    public double TendonKg { get; set; }

    public double KachalkaKg { get; set; }

    public double TarashKg { get; set; }

    public double WasteKg { get; set; }

    // Qazi foydalanuvchi tomonidan kiritilmaydi.
    // Keyinchalik kalkulyator/model tomonidan hisoblanadi.
    public double QaziKg { get; set; }

    // Eski versiya bilan moslik uchun vaqtincha saqlanadi.
    public double IntestineKg { get; set; }

    public double OtherKg { get; set; }

    public string Notes { get; set; } = string.Empty;

    // Xaridning umumiy qiymati
    public decimal TotalPurchaseCost =>
        (decimal)LiveWeightKg * PurchasePricePerKg;

    // Real o‘lchangan mahsulotlar jami.
    // Qazi bu yerga qo‘shilmaydi, chunki u hisoblangan natija.
    public double TotalMeasuredKg =>
        CleanMeatKg +
        FatKg +
        BoneKg +
        TendonKg +
        KachalkaKg +
        TarashKg +
        WasteKg;

    public double TotalMeasuredPercent =>
        LiveWeightKg > 0
            ? TotalMeasuredKg / LiveWeightKg * 100.0
            : 0;

    public double UnaccountedWeightKg =>
        Math.Max(
            0,
            LiveWeightKg - TotalMeasuredKg);

    public double CleanMeatPercent =>
        CalculatePercent(CleanMeatKg);

    public double FatPercent =>
        CalculatePercent(FatKg);

    public double BonePercent =>
        CalculatePercent(BoneKg);

    public double TendonPercent =>
        CalculatePercent(TendonKg);

    public double KachalkaPercent =>
        CalculatePercent(KachalkaKg);

    public double TarashPercent =>
        CalculatePercent(TarashKg);

    public double WastePercent =>
        CalculatePercent(WasteKg);

    public double QaziPercent =>
        CalculatePercent(QaziKg);

    private double CalculatePercent(double value)
    {
        if (LiveWeightKg <= 0)
            return 0;

        return value / LiveWeightKg * 100.0;
    }
}
