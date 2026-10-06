using QaziCalculator.Models;

namespace QaziCalculator.Services;

public class CalculationEngine
{
    public ProcessingResult CalculatePercentages(
        ProcessingResult result)
    {
        if (!double.IsFinite(result.LiveWeightKg) ||
            result.LiveWeightKg <= 0)
        {
            throw new ArgumentException(
                "Boshlang‘ich vazn 0 dan katta bo‘lishi kerak.");
        }

        return result;
    }

    public double CalculatePercentage(
        double amountKg,
        double liveWeightKg)
    {
        if (!double.IsFinite(amountKg) ||
            !double.IsFinite(liveWeightKg) ||
            liveWeightKg <= 0)
            return 0;

        return amountKg / liveWeightKg * 100.0;
    }

    // Faqat foydalanuvchi real o‘lchab kiritgan
    // 7 ta natija hisoblanadi.
    //
    // Qazi bu yerda hisobga olinmaydi,
    // chunki Qazi keyinchalik alohida model orqali
    // kalkulyator tomonidan chiqariladi.
    public double CalculateTotalMeasured(
        ProcessingResult result)
    {
        return
            result.CleanMeatKg +
            result.FatKg +
            result.BoneKg +
            result.TendonKg +
            result.KachalkaKg +
            result.TarashKg +
            result.WasteKg;
    }

    public double CalculateTotalMeasuredPercentage(
        ProcessingResult result)
    {
        if (!double.IsFinite(result.LiveWeightKg) ||
            result.LiveWeightKg <= 0)
            return 0;

        var totalMeasured =
            CalculateTotalMeasured(result);

        return
            totalMeasured /
            result.LiveWeightKg *
            100.0;
    }

    // Hali qayd qilinmagan vazn.
    public double CalculateUnaccountedWeight(
        ProcessingResult result)
    {
        if (!double.IsFinite(result.LiveWeightKg) ||
            result.LiveWeightKg <= 0)
            return 0;

        var totalMeasured =
            CalculateTotalMeasured(result);

        return Math.Max(
            0,
            result.LiveWeightKg - totalMeasured);
    }

    public bool ValidateResult(
        ProcessingResult result,
        out string errorMessage)
    {
        errorMessage = string.Empty;

        if (!double.IsFinite(result.LiveWeightKg) ||
            result.LiveWeightKg <= 0)
        {
            errorMessage =
                "Boshlang‘ich vazn 0 dan katta bo‘lishi kerak.";

            return false;
        }

        if (HasInvalidValues(result))
        {
            errorMessage =
                "Mahsulot vaznlari manfiy yoki noto‘g‘ri formatda bo‘lishi mumkin emas.";

            return false;
        }

        var totalMeasured =
            CalculateTotalMeasured(result);

        if (totalMeasured > result.LiveWeightKg)
        {
            errorMessage =
                "Jami o‘lchangan mahsulot vazni " +
                "otning tirik vaznidan katta bo‘lishi mumkin emas.";

            return false;
        }

        return true;
    }

    private bool HasInvalidValues(
        ProcessingResult result)
    {
        return
            !double.IsFinite(result.CleanMeatKg) ||
            !double.IsFinite(result.FatKg) ||
            !double.IsFinite(result.BoneKg) ||
            !double.IsFinite(result.TendonKg) ||
            !double.IsFinite(result.KachalkaKg) ||
            !double.IsFinite(result.TarashKg) ||
            !double.IsFinite(result.WasteKg) ||
            result.CleanMeatKg < 0 ||
            result.FatKg < 0 ||
            result.BoneKg < 0 ||
            result.TendonKg < 0 ||
            result.KachalkaKg < 0 ||
            result.TarashKg < 0 ||
            result.WasteKg < 0;
    }

    public double CalculateCleanMeatFatRatio(
        ProcessingResult result)
    {
        if (!double.IsFinite(result.CleanMeatKg) ||
            !double.IsFinite(result.FatKg) ||
            result.CleanMeatKg <= 0)
            return 0;

        return
            result.FatKg /
            result.CleanMeatKg;
    }

    public double CalculateFatPerCleanMeatKg(
        ProcessingResult result)
    {
        if (!double.IsFinite(result.CleanMeatKg) ||
            !double.IsFinite(result.FatKg) ||
            result.CleanMeatKg <= 0)
            return 0;

        return
            result.FatKg /
            result.CleanMeatKg;
    }
}
