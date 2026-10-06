using QaziCalculator.Models;

namespace QaziCalculator.Services;

public class StatisticsEngine
{
    public StatisticsSummary CalculateOverallStatistics(
        IEnumerable<ProcessingResult> results)
    {
        var data = results
            .Where(x =>
                x.LiveWeightKg > 0 &&
                !double.IsNaN(x.LiveWeightKg) &&
                !double.IsInfinity(x.LiveWeightKg))
            .ToList();

        return CalculateSummary(data);
    }

    public WeightRangeStatistics CalculateWeightRangeStatistics(
        IEnumerable<ProcessingResult> results,
        double minimumWeightKg,
        double maximumWeightKg)
    {
        var data = results
            .Where(x =>
                x.LiveWeightKg > 0 &&
                !double.IsNaN(x.LiveWeightKg) &&
                !double.IsInfinity(x.LiveWeightKg) &&
                x.LiveWeightKg >= minimumWeightKg &&
                x.LiveWeightKg < maximumWeightKg)
            .ToList();

        var summary = CalculateSummary(data);

        return new WeightRangeStatistics
        {
            MinimumWeightKg = minimumWeightKg,
            MaximumWeightKg = maximumWeightKg,
            SampleCount = summary.SampleCount,
            TotalLiveWeightKg = summary.TotalLiveWeightKg,
            AverageLiveWeightKg = summary.AverageLiveWeightKg,
            MedianLiveWeightKg = summary.MedianLiveWeightKg,
            MinimumLiveWeightKg = summary.MinimumLiveWeightKg,
            MaximumLiveWeightKg = summary.MaximumLiveWeightKg,
            LiveWeightStandardDeviationKg = summary.LiveWeightStandardDeviationKg,
            CleanMeat = summary.CleanMeat,
            Fat = summary.Fat,
            Bone = summary.Bone,
            Tendon = summary.Tendon,
            Kachalka = summary.Kachalka,
            Tarash = summary.Tarash,
            Waste = summary.Waste
        };
    }

    private StatisticsSummary CalculateSummary(
        IReadOnlyCollection<ProcessingResult> data)
    {
        if (data.Count == 0)
            return StatisticsSummary.Empty();

        var liveWeights = data.Select(x => x.LiveWeightKg).ToList();
        var averageLiveWeight = liveWeights.Average();

        return new StatisticsSummary
        {
            SampleCount = data.Count,
            TotalLiveWeightKg = liveWeights.Sum(),
            AverageLiveWeightKg = averageLiveWeight,
            MedianLiveWeightKg = CalculateMedian(liveWeights.OrderBy(x => x).ToList()),
            MinimumLiveWeightKg = liveWeights.Min(),
            MaximumLiveWeightKg = liveWeights.Max(),
            LiveWeightStandardDeviationKg =
                CalculateStandardDeviation(liveWeights, averageLiveWeight),
            CleanMeat = CalculateMetric(data, x => x.CleanMeatKg),
            Fat = CalculateMetric(data, x => x.FatKg),
            Bone = CalculateMetric(data, x => x.BoneKg),
            Tendon = CalculateMetric(data, x => x.TendonKg),
            Kachalka = CalculateMetric(data, x => x.KachalkaKg),
            Tarash = CalculateMetric(data, x => x.TarashKg),
            Waste = CalculateMetric(data, x => x.WasteKg)
        };
    }

    // Muayyan vaznga eng yaqin real otlar bo‘yicha statistika.
    // Bu keyinchalik xxx kg ot uchun prognoz modeliga asos bo‘ladi.
    public WeightRangeStatistics CalculateNearestWeightStatistics(
        IEnumerable<ProcessingResult> results,
        double targetWeightKg,
        double toleranceKg = 50)
    {
        if (targetWeightKg <= 0)
            return new WeightRangeStatistics();

        return CalculateWeightRangeStatistics(
            results,
            Math.Max(0, targetWeightKg - toleranceKg),
            targetWeightKg + toleranceKg);
    }

    // Clean meat va yog‘ o‘rtasidagi real tarixiy nisbat.
    public RatioStatistics CalculateCleanMeatFatRatio(
        IEnumerable<ProcessingResult> results)
    {
        var ratios = results
            .Where(x =>
                x.CleanMeatKg > 0 &&
                x.FatKg >= 0)
            .Select(x =>
                x.FatKg / x.CleanMeatKg)
            .Where(x =>
                !double.IsNaN(x) &&
                !double.IsInfinity(x))
            .ToList();

        if (ratios.Count == 0)
            return RatioStatistics.Empty();

        return new RatioStatistics
        {
            SampleCount = ratios.Count,
            AverageRatio = ratios.Average(),
            MinimumRatio = ratios.Min(),
            MaximumRatio = ratios.Max(),
            StandardDeviation =
                CalculateStandardDeviation(
                    ratios,
                    ratios.Average())
        };
    }

    private PercentageStatistics CalculateMetric(
        IEnumerable<ProcessingResult> results,
        Func<ProcessingResult, double> kilogramSelector)
    {
        var data = results
            .Select(result => new
            {
                Kg = kilogramSelector(result),
                Percent = kilogramSelector(result) /
                    result.LiveWeightKg * 100.0
            })
            .Where(x =>
                x.Kg >= 0 &&
                !double.IsNaN(x.Kg) &&
                !double.IsInfinity(x.Kg) &&
                !double.IsNaN(x.Percent) &&
                !double.IsInfinity(x.Percent))
            .ToList();

        if (data.Count == 0)
            return PercentageStatistics.Empty();

        var kilograms = data.Select(x => x.Kg).OrderBy(x => x).ToList();
        var percentages = data.Select(x => x.Percent).OrderBy(x => x).ToList();

        var averageKg = kilograms.Average();
        var averagePercent = percentages.Average();

        var standardDeviationKg =
            CalculateStandardDeviation(kilograms, averageKg);

        var standardDeviationPercent =
            CalculateStandardDeviation(percentages, averagePercent);

        return new PercentageStatistics
        {
            AverageKg = averageKg,
            MedianKg = CalculateMedian(kilograms),
            MinimumKg = kilograms.First(),
            MaximumKg = kilograms.Last(),
            StandardDeviationKg = standardDeviationKg,
            AveragePercent = averagePercent,
            MedianPercent = CalculateMedian(percentages),
            MinimumPercent = percentages.First(),
            MaximumPercent = percentages.Last(),
            StandardDeviation = standardDeviationPercent,
            SampleCount = data.Count
        };
    }

    private double CalculateMedian(
        List<double> sortedValues)
    {
        var count = sortedValues.Count;

        if (count == 0)
            return 0;

        if (count % 2 == 1)
            return sortedValues[count / 2];

        var left =
            sortedValues[(count / 2) - 1];

        var right =
            sortedValues[count / 2];

        return (left + right) / 2.0;
    }

    private double CalculateStandardDeviation(
        List<double> values,
        double average)
    {
        if (values.Count <= 1)
            return 0;

        var sum = values.Sum(value =>
        {
            var difference =
                value - average;

            return difference * difference;
        });

        return Math.Sqrt(
            sum / (values.Count - 1));
    }
}

public class PercentageStatistics
{
    public int SampleCount { get; set; }

    public double AverageKg { get; set; }

    public double MedianKg { get; set; }

    public double MinimumKg { get; set; }

    public double MaximumKg { get; set; }

    public double StandardDeviationKg { get; set; }

    public double AveragePercent { get; set; }

    public double MedianPercent { get; set; }

    public double MinimumPercent { get; set; }

    public double MaximumPercent { get; set; }

    public double StandardDeviation { get; set; }

    public static PercentageStatistics Empty()
    {
        return new PercentageStatistics();
    }
}

public class RatioStatistics
{
    public int SampleCount { get; set; }

    // Masalan: 0.25 = 1 kg toza go‘shtga
    // o‘rtacha 0.25 kg yog‘.
    public double AverageRatio { get; set; }

    public double MinimumRatio { get; set; }

    public double MaximumRatio { get; set; }

    public double StandardDeviation { get; set; }

    public bool HasEnoughData =>
        SampleCount >= 5;

    public static RatioStatistics Empty()
    {
        return new RatioStatistics();
    }
}

public class StatisticsSummary
{
    public int SampleCount { get; set; }

    public double TotalLiveWeightKg { get; set; }

    public double AverageLiveWeightKg { get; set; }

    public double MedianLiveWeightKg { get; set; }

    public double MinimumLiveWeightKg { get; set; }

    public double MaximumLiveWeightKg { get; set; }

    public double LiveWeightStandardDeviationKg { get; set; }

    public PercentageStatistics CleanMeat { get; set; }
        = PercentageStatistics.Empty();

    public PercentageStatistics Fat { get; set; }
        = PercentageStatistics.Empty();

    public PercentageStatistics Bone { get; set; }
        = PercentageStatistics.Empty();

    public PercentageStatistics Tendon { get; set; }
        = PercentageStatistics.Empty();

    public PercentageStatistics Kachalka { get; set; }
        = PercentageStatistics.Empty();

    public PercentageStatistics Tarash { get; set; }
        = PercentageStatistics.Empty();

    public PercentageStatistics Waste { get; set; }
        = PercentageStatistics.Empty();

    public static StatisticsSummary Empty()
    {
        return new StatisticsSummary();
    }
}

public class WeightRangeStatistics : StatisticsSummary
{
    public double MinimumWeightKg { get; set; }

    public double MaximumWeightKg { get; set; }
}
