using QaziCalculator.Data;

namespace QaziCalculator.Views;

public partial class ReportsPage : ContentPage
{
    private readonly DatabaseService _databaseService = new();
    private bool _isInitializing;

    public ReportsPage()
    {
        InitializeComponent();
        _isInitializing = true;
        PeriodPicker.SelectedIndex = 0;
        StartDatePicker.Date = DateTime.Today;
        EndDatePicker.Date = DateTime.Today;
        _isInitializing = false;
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        await LoadReportAsync();
    }

    private async void PeriodPicker_SelectedIndexChanged(object? sender, EventArgs e)
    {
        CustomRangeLayout.IsVisible = PeriodPicker.SelectedIndex == 4;
        if (!_isInitializing && PeriodPicker.SelectedIndex != 4)
            await LoadReportAsync();
    }

    private async void RefreshButton_Clicked(object? sender, EventArgs e)
    {
        if (PeriodPicker.SelectedIndex == 4 &&
            EndDatePicker.Date?.Date < StartDatePicker.Date?.Date)
        {
            await DisplayAlertAsync("Sana xatoligi", "Tugash sanasi boshlanish sanasidan oldin bo'lmasin.", "OK");
            return;
        }

        await LoadReportAsync();
    }

    private async Task LoadReportAsync()
    {
        try
        {
            var (start, end, label) = GetRange();
            PeriodLabel.Text = label;
            var allBatches = await _databaseService.GetHorseBatchesAsync();
            var batches = allBatches
                .Where(x => x.CreatedAt >= start && x.CreatedAt < end)
                .ToList();
            var results = (await _databaseService.GetAllProcessingResultsAsync())
                .Where(x =>
                    x.LiveWeightKg > 0 &&
                    double.IsFinite(x.LiveWeightKg) &&
                    x.CreatedAt >= start &&
                    x.CreatedAt < end)
                .ToList();
            var expenses = (await _databaseService.GetExpensesAsync())
                .Where(x => x.CreatedAt >= start && x.CreatedAt < end)
                .ToList();

            HorseCountLabel.Text = batches.Count.ToString("N0");
            LiveWeightLabel.Text = $"{results.Sum(x => x.LiveWeightKg):N2} kg";
            ProductionLabel.Text = $"{results.Sum(x => x.TotalMeasuredKg):N2} kg";
            ExpensesLabel.Text = $"{expenses.Sum(x => x.Amount):N0} so'm";
            PurchaseCostLabel.Text = $"{batches.Sum(x => x.TotalPurchaseCost):N0} so'm";
            SampleCountLabel.Text = results.Count.ToString("N0");
            AverageWeightLabel.Text = results.Count > 0
                ? $"{results.Average(x => x.LiveWeightKg):N2} kg"
                : "Ma'lumot yetarli emas";
            AverageProductionLabel.Text = results.Count > 0
                ? $"{results.Average(x => x.TotalMeasuredKg):N2} kg"
                : "Ma'lumot yetarli emas";
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(ex);
            await DisplayAlertAsync("Xatolik", "Hisobot ma'lumotlarini yuklab bo'lmadi.", "OK");
        }
    }

    private (DateTime Start, DateTime End, string Label) GetRange()
    {
        var today = DateTime.Today;
        return PeriodPicker.SelectedIndex switch
        {
            1 => (today.AddDays(-6), today.AddDays(1), "Oxirgi 7 kun"),
            2 => (new DateTime(today.Year, today.Month, 1), new DateTime(today.Year, today.Month, 1).AddMonths(1), "Bu oy"),
            3 => (new DateTime(today.Year, 1, 1), new DateTime(today.Year + 1, 1, 1), "Bu yil"),
            4 => (StartDatePicker.Date?.Date ?? today, (EndDatePicker.Date?.Date ?? today).AddDays(1), "Maxsus davr"),
            _ => (today, today.AddDays(1), "Bugun")
        };
    }

    private async void ProductsButton_Clicked(object? sender, EventArgs e) =>
        await Shell.Current.GoToAsync(nameof(ProductsPage));
}
