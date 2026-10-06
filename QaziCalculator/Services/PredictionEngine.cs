using QaziCalculator.Models;

namespace QaziCalculator.Services;

public class PredictionEngine
{
    private const int MinimumSamplesForPrediction = 5;

    public WeightPrediction Predict(
        IEnumerable<ProcessingResult> results,
        double targetWeightKg)
    {
        if (!double.IsFinite(targetWeightKg) ||
            targetWeightKg <= 0)
            throw new ArgumentException(
                "Ot vazni 0 dan katta bo‘lishi kerak.");

        var data = results
            .Where(x =>
                x.LiveWeightKg > 0 &&
                double.IsFinite(x.LiveWeightKg))
            .ToList();

        if (data.Count < MinimumSamplesForPrediction)
            return WeightPrediction.NotEnoughData(
                targetWeightKg,
                data.Count);

        return new WeightPrediction
        {
            TargetWeightKg = targetWeightKg,
            SampleCount = data.Count,

            CleanMeat = PredictMetric(
                data,
                targetWeightKg,
                x => x.CleanMeatPercent),

            Fat = PredictMetric(
                data,
                targetWeightKg,
                x => x.FatPercent),

            Bone = PredictMetric(
                data,
                targetWeightKg,
                x => x.BonePercent),

            Tendon = PredictMetric(
                data,
                targetWeightKg,
                x => x.TendonPercent),

            Kachalka = PredictMetric(
                data,
                targetWeightKg,
                x => x.KachalkaPercent),

            Tarash = PredictMetric(
                data,
                targetWeightKg,
                x => x.TarashPercent),

            Waste = PredictMetric(
                data,
                targetWeightKg,
                x => x.WastePercent),

            Qazi = PredictionMetric.NotEnoughData(
                data.Count)
        };
    }

    private PredictionMetric PredictMetric(
        List<ProcessingResult> data,
        double targetWeightKg,
        Func<ProcessingResult, double> selector)
    {
        var weightedValues = data
            .Select(x =>
            {
                var distance =
                    Math.Abs(
                        x.LiveWeightKg -
                        targetWeightKg);

                // Vazni targetga yaqin otlarga
                // ko‘proq og‘irlik beriladi.
                var weight =
                    1.0 / (1.0 + distance);

                return new WeightedValue
                {
                    Value = selector(x),
                    Weight = weight
                };
            })
            .Where(x =>
                !double.IsNaN(x.Value) &&
                !double.IsInfinity(x.Value) &&
                x.Value >= 0)
            .ToList();

        if (weightedValues.Count < MinimumSamplesForPrediction)
        {
            return PredictionMetric.NotEnoughData(
                weightedValues.Count);
        }

        var totalWeight =
            weightedValues.Sum(x => x.Weight);

        if (totalWeight <= 0)
        {
            return PredictionMetric.NotEnoughData(
                weightedValues.Count);
        }

        var predictedPercent =
            weightedValues.Sum(
                x => x.Value * x.Weight)
            / totalWeight;

        var variance =
            weightedValues.Sum(x =>
            {
                var difference =
                    x.Value -
                    predictedPercent;

                return
                    x.Weight *
                    difference *
                    difference;
            })
            / totalWeight;

        var standardDeviation =
            Math.Sqrt(
                Math.Max(0, variance));

        var confidence =
            CalculateConfidence(
                weightedValues.Count,
                standardDeviation);

        return new PredictionMetric
        {
            PredictedPercent =
                Math.Max(0, predictedPercent),

            StandardDeviation =
                standardDeviation,

            ConfidenceScore =
                confidence,

            SampleCount =
                weightedValues.Count
        };
    }

    private double CalculateConfidence(
        int sampleCount,
        double standardDeviation)
    {
        if (sampleCount < MinimumSamplesForPrediction)
            return 0;

        // Namuna ko‘paygani sari ishonchlilik oshadi.
        var sampleFactor =
            1.0 -
            Math.Exp(
                -sampleCount / 50.0);

        // Natijalar tarqalishi katta bo‘lsa,
        // ishonchlilik kamayadi.
        var variationFactor =
            1.0 /
            (1.0 + standardDeviation);

        var score =
            sampleFactor *
            variationFactor *
            100.0;

        return Math.Clamp(
            score,
            0,
            100);
    }

    private class WeightedValue
    {
        public double Value { get; set; }

        public double Weight { get; set; }
    }
}

public class PredictionMetric
{
    public double PredictedPercent { get; set; }

    public double StandardDeviation { get; set; }

    public double ConfidenceScore { get; set; }

    public int SampleCount { get; set; }

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

    public double PredictKg(
        double liveWeightKg)
    {
        if (!HasEnoughData ||
            liveWeightKg <= 0)
        {
            return 0;
        }

        return
            liveWeightKg *
            PredictedPercent /
            100.0;
    }

    public static PredictionMetric NotEnoughData(
        int sampleCount)
    {
        return new PredictionMetric
        {
            SampleCount =
                sampleCount,

            PredictedPercent = 0,

            StandardDeviation = 0,

            ConfidenceScore = 0
        };
    }
}

public class WeightPrediction
{
    public double TargetWeightKg { get; set; }

    public int SampleCount { get; set; }

    public PredictionMetric CleanMeat { get; set; }
        = PredictionMetric.NotEnoughData(0);

    public PredictionMetric Fat { get; set; }
        = PredictionMetric.NotEnoughData(0);

    public PredictionMetric Bone { get; set; }
        = PredictionMetric.NotEnoughData(0);

    public PredictionMetric Tendon { get; set; }
        = PredictionMetric.NotEnoughData(0);

    public PredictionMetric Kachalka { get; set; }
        = PredictionMetric.NotEnoughData(0);

    public PredictionMetric Tarash { get; set; }
        = PredictionMetric.NotEnoughData(0);

    public PredictionMetric Waste { get; set; }
        = PredictionMetric.NotEnoughData(0);

    // Qazi hozircha ataylab prognoz qilinmaydi.
    //
    // Sababi: Qazi bo‘yicha haqiqiy tarixiy o‘lchovlar
    // yig‘ilmaguncha qazi foizini o‘zimizdan chiqarish
    // noto‘g‘ri bo‘ladi.
    //
    // Keyingi bosqichda Qazi modeli:
    // real go‘sht + real yog‘ + qazi tarkibi
    // bo‘yicha alohida quriladi.
    public PredictionMetric Qazi { get; set; }
        = PredictionMetric.NotEnoughData(0);

    public bool HasEnoughData =>
        SampleCount >= 5;

    public static WeightPrediction NotEnoughData(
        double targetWeightKg,
        int sampleCount)
    {
        return new WeightPrediction
        {
            TargetWeightKg =
                targetWeightKg,

            SampleCount =
                sampleCount,

            CleanMeat =
                PredictionMetric.NotEnoughData(
                    sampleCount),

            Fat =
                PredictionMetric.NotEnoughData(
                    sampleCount),

            Bone =
                PredictionMetric.NotEnoughData(
                    sampleCount),

            Tendon =
                PredictionMetric.NotEnoughData(
                    sampleCount),

            Kachalka =
                PredictionMetric.NotEnoughData(
                    sampleCount),

            Tarash =
                PredictionMetric.NotEnoughData(
                    sampleCount),

            Waste =
                PredictionMetric.NotEnoughData(
                    sampleCount),

            Qazi =
                PredictionMetric.NotEnoughData(
                    sampleCount)
        };
    }
}
