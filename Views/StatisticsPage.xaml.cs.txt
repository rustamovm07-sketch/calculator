using System.Collections.ObjectModel;
using System.Globalization;
using QaziCalculator.Data;
using QaziCalculator.Models;
using QaziCalculator.Services;

namespace QaziCalculator.Views;

public partial class StatisticsPage : ContentPage
{
    private readonly DatabaseService _databaseService = new();
    private readonly StatisticsEngine _statisticsEngine = new();
    private readonly PredictionEngine _predictionEngine = new();
    private List<ProcessingResult> _periodResults = [];
    private int _periodHorseCount;
    private DateFilter _selectedFilter = DateFilter.Today;
    private double? _analyzedTargetWeightKg;

    public ObservableCollection<MetricStatisticsDisplay> HistoricalMetrics { get; } = [];

    public ObservableCollection<MetricStatisticsDisplay> NearestWeightMetrics { get; } = [];

    public ObservableCollection<PredictionDisplay> PredictionMetrics { get; } = [];

    public StatisticsPage()
    {
        InitializeComponent();
        BindingContext = this;
        StartDatePicker.Date = DateTime.Today;
        EndDatePicker.Date = DateTime.Today;
        UpdateFilterButtons();
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        UpdateFilterButtons();
        await LoadStatisticsAsync();
    }

    private async void TodayFilterButton_Clicked(object? sender, EventArgs e)
    {
        _selectedFilter = DateFilter.Today;
        await ApplySelectedFilterAsync();
    }

    private async void SevenDaysFilterButton_Clicked(object? sender, EventArgs e)
    {
        _selectedFilter = DateFilter.SevenDays;
        await ApplySelectedFilterAsync();
    }

    private async void MonthFilterButton_Clicked(object? sender, EventArgs e)
    {
        _selectedFilter = DateFilter.ThisMonth;
        await ApplySelectedFilterAsync();
    }

    private async void YearFilterButton_Clicked(object? sender, EventArgs e)
    {
        _selectedFilter = DateFilter.ThisYear;
        await ApplySelectedFilterAsync();
    }

    private void CustomFilterButton_Clicked(object? sender, EventArgs e)
    {
        _selectedFilter = DateFilter.Custom;
        CustomDateLayout.IsVisible = true;
        UpdateFilterButtons();
        PeriodLabel.Text = "Maxsus davrni tanlang";
    }

    private async void ApplyCustomFilterButton_Clicked(object? sender, EventArgs e)
    {
        var startDate = StartDatePicker.Date?.Date ?? DateTime.Today;
        var endDate = EndDatePicker.Date?.Date ?? DateTime.Today;

        if (endDate < startDate)
        {
            await DisplayAlertAsync(
                "Sana xatoligi",
                "Tugash sanasi boshlanish sanasidan oldin bo'lishi mumkin emas.",
                "OK");
            return;
        }

        await LoadStatisticsAsync();
    }

    private async void RefreshButton_Clicked(object? sender, EventArgs e)
    {
        await LoadStatisticsAsync();
    }

    private async Task ApplySelectedFilterAsync()
    {
        CustomDateLayout.IsVisible = false;
        UpdateFilterButtons();
        await LoadStatisticsAsync();
    }

    private async Task LoadStatisticsAsync()
    {
        try
        {
            var (start, endExclusive, label) = GetSelectedDateRange();
            PeriodLabel.Text = label;

            var allResults = await _databaseService.GetAllProcessingResultsAsync();
            var allBatches = await _databaseService.GetHorseBatchesAsync();
            _periodHorseCount = allBatches.Count(batch =>
                batch.CreatedAt >= start &&
                batch.CreatedAt < endExclusive);
            _periodResults = allResults
                .Where(result =>
                    result.LiveWeightKg > 0 &&
                    !double.IsNaN(result.LiveWeightKg) &&
                    !double.IsInfinity(result.LiveWeightKg) &&
                    result.CreatedAt >= start &&
                    result.CreatedAt < endExclusive)
                .ToList();

            var summary = _statisticsEngine.CalculateOverallStatistics(_periodResults);
            UpdateHistoricalSummary(summary);
            UpdateWeightAnalysis();
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(ex);
            await DisplayAlertAsync(
                "Xatolik",
                "Statistika ma'lumotlarini yuklab bo'lmadi.",
                "OK");
        }
    }

    private (DateTime Start, DateTime EndExclusive, string Label) GetSelectedDateRange()
    {
        var today = DateTime.Today;
        var customStartDate = StartDatePicker.Date?.Date ?? today;
        var customEndDate = EndDatePicker.Date?.Date ?? today;

        return _selectedFilter switch
        {
            DateFilter.Today => (today, today.AddDays(1), "Bugun"),
            DateFilter.SevenDays => (today.AddDays(-6), today.AddDays(1), "Oxirgi 7 kun"),
            DateFilter.ThisMonth =>
                (new DateTime(today.Year, today.Month, 1),
                    new DateTime(today.Year, today.Month, 1).AddMonths(1),
                    "Bu oy"),
            DateFilter.ThisYear =>
                (new DateTime(today.Year, 1, 1),
                    new DateTime(today.Year + 1, 1, 1),
                    "Bu yil"),
            DateFilter.Custom =>
                (customStartDate,
                    customEndDate.AddDays(1),
                    $"{customStartDate:dd.MM.yyyy} - {customEndDate:dd.MM.yyyy}"),
            _ => throw new InvalidOperationException("Noma'lum sana filtri.")
        };
    }

    private void UpdateHistoricalSummary(StatisticsSummary summary)
    {
        var hasData = summary.SampleCount > 0;
        NoHistoricalDataLabel.IsVisible = !hasData;
        HorseCountLabel.Text = _periodHorseCount.ToString("N0");
        TotalLiveWeightLabel.Text = hasData
            ? $"{summary.TotalLiveWeightKg:N2} kg"
            : "Ma'lumot yetarli emas";
        AverageLiveWeightLabel.Text = hasData
            ? $"{summary.AverageLiveWeightKg:N2} kg"
            : "Ma'lumot yetarli emas";
        LiveWeightRangeLabel.Text = hasData
            ? $"{summary.MedianLiveWeightKg:N2} / {summary.MinimumLiveWeightKg:N2} / {summary.MaximumLiveWeightKg:N2} kg"
            : "Ma'lumot yetarli emas";
        LiveWeightDeviationLabel.Text = hasData
            ? $"Tirik vazn SD: {summary.LiveWeightStandardDeviationKg:N2} kg"
            : "Tirik vazn SD: Ma'lumot yetarli emas";

        HistoricalMetrics.Clear();
        if (!hasData)
            return;

        HistoricalMetrics.Add(new MetricStatisticsDisplay("Toza go'sht", summary.CleanMeat));
        HistoricalMetrics.Add(new MetricStatisticsDisplay("Yog'", summary.Fat));
        HistoricalMetrics.Add(new MetricStatisticsDisplay("Suyak", summary.Bone));
        HistoricalMetrics.Add(new MetricStatisticsDisplay("Pay", summary.Tendon));
        HistoricalMetrics.Add(new MetricStatisticsDisplay("Kachalka", summary.Kachalka));
        HistoricalMetrics.Add(new MetricStatisticsDisplay("Tarash", summary.Tarash));
        HistoricalMetrics.Add(new MetricStatisticsDisplay("Chiqindi", summary.Waste));
    }

    private async void AnalyzeWeightButton_Clicked(object? sender, EventArgs e)
    {
        if (!TryParseWeight(TargetWeightEntry.Text, out var targetWeightKg) ||
            double.IsNaN(targetWeightKg) ||
            double.IsInfinity(targetWeightKg) ||
            targetWeightKg <= 0)
        {
            await DisplayAlertAsync(
                "Vazn xatoligi",
                "Maqsad vaznni 0 dan katta son sifatida kiriting.",
                "OK");
            return;
        }

        _analyzedTargetWeightKg = targetWeightKg;
        UpdateWeightAnalysis();
    }

    private void UpdateWeightAnalysis()
    {
        NearestWeightMetrics.Clear();
        PredictionMetrics.Clear();

        if (_analyzedTargetWeightKg is not double targetWeightKg)
        {
            NearestWeightSummaryLabel.Text = "Maqsad vaznni kiriting.";
            PredictionAvailabilityLabel.Text = "Maqsad vaznni kiriting.";
            return;
        }

        var nearest = _statisticsEngine.CalculateNearestWeightStatistics(
            _periodResults,
            targetWeightKg);

        NearestWeightSummaryLabel.Text = nearest.SampleCount > 0
            ? $"Haqiqiy yozuvlar: {nearest.SampleCount} ta (maqsad vazndan ±50 kg oralig'i)."
            : "Bu davrda shu vazn oralig'iga mos real yozuv yo'q.";

        if (nearest.SampleCount > 0)
        {
            NearestWeightMetrics.Add(new MetricStatisticsDisplay("Toza go'sht", nearest.CleanMeat));
            NearestWeightMetrics.Add(new MetricStatisticsDisplay("Yog'", nearest.Fat));
            NearestWeightMetrics.Add(new MetricStatisticsDisplay("Suyak", nearest.Bone));
            NearestWeightMetrics.Add(new MetricStatisticsDisplay("Pay", nearest.Tendon));
            NearestWeightMetrics.Add(new MetricStatisticsDisplay("Kachalka", nearest.Kachalka));
            NearestWeightMetrics.Add(new MetricStatisticsDisplay("Tarash", nearest.Tarash));
            NearestWeightMetrics.Add(new MetricStatisticsDisplay("Chiqindi", nearest.Waste));
        }

        var prediction = _predictionEngine.Predict(_periodResults, targetWeightKg);
        PredictionAvailabilityLabel.Text = prediction.HasEnoughData
            ? $"Maqsad: {targetWeightKg:N2} kg. Modeldagi real kuzatuvlar: {prediction.SampleCount}."
            : $"Maqsad: {targetWeightKg:N2} kg. Prognoz uchun ma'lumot yetarli emas ({prediction.SampleCount}/5 real yozuv).";

        AddPrediction("Toza go'sht", prediction.CleanMeat, targetWeightKg);
        AddPrediction("Yog'", prediction.Fat, targetWeightKg);
        AddPrediction("Suyak", prediction.Bone, targetWeightKg);
        AddPrediction("Pay", prediction.Tendon, targetWeightKg);
        AddPrediction("Kachalka", prediction.Kachalka, targetWeightKg);
        AddPrediction("Tarash", prediction.Tarash, targetWeightKg);
        AddPrediction("Chiqindi", prediction.Waste, targetWeightKg);
    }

    private void AddPrediction(
        string name,
        PredictionMetric metric,
        double targetWeightKg)
    {
        var available = metric.HasEnoughData;
        PredictionMetrics.Add(new PredictionDisplay
        {
            Name = name,
            ReliabilityText = available ? $"Ishonchlilik: {metric.ReliabilityLevel}" : "Ma'lumot yetarli emas",
            PredictionText = available
                ? $"Prognoz: {metric.PredictKg(targetWeightKg):N2} kg ({metric.PredictedPercent:N2}%)"
                : "Prognoz hisoblanmadi.",
            ConfidenceText = available
                ? $"SD: {metric.StandardDeviation:N2} foiz punkt | Ishonch: {metric.ConfidenceScore:N0}% | Namuna: {metric.SampleCount}"
                : $"Namuna: {metric.SampleCount}/5"
        });
    }

    private static bool TryParseWeight(string? value, out double weight)
    {
        return double.TryParse(
                   value,
                   NumberStyles.Float | NumberStyles.AllowThousands,
                   CultureInfo.CurrentCulture,
                   out weight) ||
               double.TryParse(
                   value,
                   NumberStyles.Float | NumberStyles.AllowThousands,
                   CultureInfo.InvariantCulture,
                   out weight);
    }

    private void UpdateFilterButtons()
    {
        CustomDateLayout.IsVisible = _selectedFilter == DateFilter.Custom;
        SetFilterButton(TodayFilterButton, DateFilter.Today);
        SetFilterButton(SevenDaysFilterButton, DateFilter.SevenDays);
        SetFilterButton(MonthFilterButton, DateFilter.ThisMonth);
        SetFilterButton(YearFilterButton, DateFilter.ThisYear);
        SetFilterButton(CustomFilterButton, DateFilter.Custom);
    }

    private void SetFilterButton(Button button, DateFilter filter)
    {
        var active = _selectedFilter == filter;
        var darkTheme = Application.Current?.RequestedTheme == AppTheme.Dark;
        button.BackgroundColor = active
            ? darkTheme ? Color.FromArgb("#C45A68") : Color.FromArgb("#8B1E2D")
            : darkTheme ? Color.FromArgb("#29292F") : Color.FromArgb("#EFEFF2");
        button.TextColor = active
            ? Colors.White
            : darkTheme ? Colors.White : Color.FromArgb("#111111");
    }

    private enum DateFilter
    {
        Today,
        SevenDays,
        ThisMonth,
        ThisYear,
        Custom
    }
}

public sealed class MetricStatisticsDisplay
{
    public MetricStatisticsDisplay(string name, PercentageStatistics statistics)
    {
        Name = name;
        SampleCountText = statistics.SampleCount > 0
            ? $"Namuna: {statistics.SampleCount}"
            : "Ma'lumot yetarli emas";
        AverageKgText = statistics.SampleCount > 0
            ? $"O'rtacha: {statistics.AverageKg:N2} kg"
            : "O'rtacha: Ma'lumot yetarli emas";
        AveragePercentText = statistics.SampleCount > 0
            ? $"O'rtacha: {statistics.AveragePercent:N2}%"
            : "O'rtacha: Ma'lumot yetarli emas";
        MedianKgText = statistics.SampleCount > 0
            ? $"Median: {statistics.MedianKg:N2} kg"
            : "Median: Ma'lumot yetarli emas";
        MedianPercentText = statistics.SampleCount > 0
            ? $"Median: {statistics.MedianPercent:N2}%"
            : "Median: Ma'lumot yetarli emas";
        MinimumKgText = statistics.SampleCount > 0
            ? $"Min: {statistics.MinimumKg:N2} kg"
            : "Min: Ma'lumot yetarli emas";
        MinimumPercentText = statistics.SampleCount > 0
            ? $"Min: {statistics.MinimumPercent:N2}%"
            : "Min: Ma'lumot yetarli emas";
        MaximumKgText = statistics.SampleCount > 0
            ? $"Max: {statistics.MaximumKg:N2} kg"
            : "Max: Ma'lumot yetarli emas";
        MaximumPercentText = statistics.SampleCount > 0
            ? $"Max: {statistics.MaximumPercent:N2}%"
            : "Max: Ma'lumot yetarli emas";
        StandardDeviationKgText = statistics.SampleCount > 0
            ? $"SD: {statistics.StandardDeviationKg:N2} kg"
            : "SD: Ma'lumot yetarli emas";
        StandardDeviationPercentText = statistics.SampleCount > 0
            ? $"SD: {statistics.StandardDeviation:N2}%"
            : "SD: Ma'lumot yetarli emas";
    }

    public string Name { get; }
    public string SampleCountText { get; }
    public string AverageKgText { get; }
    public string AveragePercentText { get; }
    public string MedianKgText { get; }
    public string MedianPercentText { get; }
    public string MinimumKgText { get; }
    public string MinimumPercentText { get; }
    public string MaximumKgText { get; }
    public string MaximumPercentText { get; }
    public string StandardDeviationKgText { get; }
    public string StandardDeviationPercentText { get; }
}

public sealed class PredictionDisplay
{
    public string Name { get; init; } = string.Empty;
    public string ReliabilityText { get; init; } = string.Empty;
    public string PredictionText { get; init; } = string.Empty;
    public string ConfidenceText { get; init; } = string.Empty;
}
