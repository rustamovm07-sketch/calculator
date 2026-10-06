using QaziCalculator.Models;

namespace QaziCalculator.Services;

public class QaziPredictionEngine
{
    private const int MinimumSamples = 5;

    public QaziPrediction Predict(
        IEnumerable<QaziComposition> compositions,
        double targetQaziKg)
    {
        if (!double.IsFinite(targetQaziKg) ||
            targetQaziKg <= 0)
            throw new ArgumentException(
                "Qazi vazni 0 dan katta bo‘lishi kerak.");

        var data = compositions
            .Where(x =>
                x.TotalQaziKg > 0 &&
                double.IsFinite(x.TotalQaziKg) &&
                x.MeatKg >= 0 &&
                double.IsFinite(x.MeatKg) &&
                x.FatKg >= 0 &&
                double.IsFinite(x.FatKg) &&
                x.MeatKg + x.FatKg <= x.TotalQaziKg)
            .ToList();

        if (data.Count < MinimumSamples)
        {
            return QaziPrediction.NotEnoughData(
                targetQaziKg,
                data.Count);
        }

        var meatValues =
            data.Select(x => x.MeatPerQaziKg)
                .ToList();

        var fatValues =
            data.Select(x => x.FatPerQaziKg)
                .ToList();

        var meatStats =
            CalculateStatistics(meatValues);

        var fatStats =
            CalculateStatistics(fatValues);

        var predictedMeatKg =
            targetQaziKg *
            meatStats.Average;

        var predictedFatKg =
            targetQaziKg *
            fatStats.Average;

        var confidence =
            CalculateConfidence(
                data.Count,
                meatStats.StandardDeviation,
                fatStats.StandardDeviation);

        return new QaziPrediction
        {
            TargetQaziKg =
                targetQaziKg,

            SampleCount =
                data.Count,

            MeatPerQaziKg =
                meatStats.Average,

            FatPerQaziKg =
                fatStats.Average,

            PredictedMeatKg =
                predictedMeatKg,

            PredictedFatKg =
                predictedFatKg,

            MeatStandardDeviation =
                meatStats.StandardDeviation,

            FatStandardDeviation =
                fatStats.StandardDeviation,

            ConfidenceScore =
                confidence
        };
    }

    // Yangi ot uchun qazi tarkibini taxmin qilish.
    //
    // Bu metod qazi tarkibining tarixiy nisbatini
    // yangi otning hisoblangan qazi miqdoriga qo‘llaydi.
    public QaziPrediction PredictFromQaziKg(
        IEnumerable<QaziComposition> compositions,
        double qaziKg)
    {
        return Predict(
            compositions,
            qaziKg);
    }

    private SimpleStatistics CalculateStatistics(
        IEnumerable<double> values)
    {
        var data = values
            .Where(x =>
                !double.IsNaN(x) &&
                !double.IsInfinity(x) &&
                x >= 0)
            .ToList();

        if (data.Count == 0)
            return SimpleStatistics.Empty();

        var average =
            data.Average();

        var variance =
            data.Count > 1
                ? data.Sum(x =>
                {
                    var difference =
                        x - average;

                    return difference * difference;
                }) / (data.Count - 1)
                : 0;

        return new SimpleStatistics
        {
            Average =
                average,

            StandardDeviation =
                Math.Sqrt(
                    Math.Max(0, variance))
        };
    }

    private double CalculateConfidence(
        int sampleCount,
        double meatStandardDeviation,
        double fatStandardDeviation)
    {
        if (sampleCount < MinimumSamples)
            return 0;

        var sampleFactor =
            1.0 -
            Math.Exp(
                -sampleCount / 50.0);

        var averageVariation =
            (meatStandardDeviation +
             fatStandardDeviation) / 2.0;

        var variationFactor =
            1.0 /
            (1.0 + averageVariation);

        return Math.Clamp(
            sampleFactor *
            variationFactor *
            100.0,
            0,
            100);
    }

    private class SimpleStatistics
    {
        public double Average { get; set; }

        public double StandardDeviation { get; set; }

        public static SimpleStatistics Empty()
        {
            return new SimpleStatistics();
        }
    }
}

public class QaziPrediction
{
    public double TargetQaziKg { get; set; }

    public int SampleCount { get; set; }

    // 1 kg qazi uchun tarixiy o‘rtacha go‘sht.
    public double MeatPerQaziKg { get; set; }

    // 1 kg qazi uchun tarixiy o‘rtacha yog‘.
    public double FatPerQaziKg { get; set; }

    public double PredictedMeatKg { get; set; }

    public double PredictedFatKg { get; set; }

    public double MeatStandardDeviation { get; set; }

    public double FatStandardDeviation { get; set; }

    public double ConfidenceScore { get; set; }

    public bool HasEnoughData =>
        SampleCount >= 5;

    public string ReliabilityLevel
    {
        get
        {
            if (!HasEnoughData)
                return "Ma'lumot yetarli emas";

            if (ConfidenceScore >= 80)
                return "Yuqori";

            if (ConfidenceScore >= 60)
                return "O‘rta";

            return "Past";
        }
    }

    public static QaziPrediction NotEnoughData(
        double targetQaziKg,
        int sampleCount)
    {
        return new QaziPrediction
        {
            TargetQaziKg =
                targetQaziKg,

            SampleCount =
                sampleCount,

            ConfidenceScore =
                0
        };
    }
}
