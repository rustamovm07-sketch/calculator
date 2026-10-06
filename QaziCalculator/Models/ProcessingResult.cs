using QaziCalculator.Models;

namespace QaziCalculator.Models;

public class ProcessingResult
{
    public int Id { get; set; }

    public int HorseBatchId { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.Now;

    // Otning tirik vazni
    public double LiveWeightKg { get; set; }

    // Foydalanuvchi real o‘lchab kiritadigan natijalar
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

    // Eski baza va keyingi migrationlar bilan moslik uchun vaqtincha saqlanadi.
    // UI orqali foydalanuvchidan olinmaydi.
    public double IntestineKg { get; set; }

    public double OtherKg { get; set; }

    // Foizlar tirik vaznga nisbatan hisoblanadi.
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

    // Faqat real o‘lchangan qayta ishlash natijalari.
    // Qazi bu summaga qo‘shilmaydi, chunki u kalkulyator tomonidan chiqariladi.
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

    // Hali hisobga olinmagan vazn.
    public double UnaccountedWeightKg =>
        Math.Max(
            0,
            LiveWeightKg - TotalMeasuredKg);

    private double CalculatePercent(double value)
    {
        if (LiveWeightKg <= 0)
            return 0;

        return value / LiveWeightKg * 100.0;
    }
}
