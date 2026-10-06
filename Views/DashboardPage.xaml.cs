using QaziCalculator.Data;
using QaziCalculator.Models;

namespace QaziCalculator.Views;

public partial class DashboardPage : ContentPage
{
    private readonly DatabaseService _databaseService = new();

    public DashboardPage()
    {
        InitializeComponent();
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        await LoadDashboardAsync();
    }

    private async Task LoadDashboardAsync()
    {
        try
        {
            var today = DateTime.Today;
            var batches = await _databaseService.GetHorseBatchesAsync();
            var todaysBatches = batches
                .Where(batch => batch.CreatedAt >= today && batch.CreatedAt < today.AddDays(1))
                .ToList();

            TodayHorsesLabel.Text = todaysBatches.Count.ToString("N0");
            TodayWeightLabel.Text = $"{todaysBatches.Sum(batch => batch.LiveWeightKg):N2} kg";
            TodayProductionLabel.Text =
                $"{todaysBatches.Sum(batch => batch.TotalMeasuredKg):N2} kg";

            RecentBatchesLayout.Children.Clear();
            RecentEmptyLabel.IsVisible = batches.Count == 0;

            foreach (var batch in batches.Take(5))
                RecentBatchesLayout.Children.Add(CreateRecentBatchView(batch));
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(ex);
            await DisplayAlertAsync(
                "Xatolik",
                "Bosh sahifa ma'lumotlarini yuklab bo'lmadi.",
                "OK");
        }
    }

    private static View CreateRecentBatchView(HorseBatch batch)
    {
        var row = new Grid
        {
            ColumnDefinitions =
            {
                new ColumnDefinition(GridLength.Star),
                new ColumnDefinition(GridLength.Auto)
            },
            ColumnSpacing = 12,
            Padding = new Thickness(0, 8)
        };

        var details = new VerticalStackLayout { Spacing = 2 };
        details.Children.Add(new Label
        {
            Text = batch.Name,
            FontAttributes = FontAttributes.Bold,
            FontSize = 15
        });
        details.Children.Add(new Label
        {
            Text = batch.CreatedAt.ToString("dd.MM.yyyy HH:mm"),
            FontSize = 12,
            TextColor = Color.FromArgb("#6B7280")
        });

        row.Add(details, 0, 0);
        row.Add(new Label
        {
            Text = $"{batch.LiveWeightKg:N2} kg",
            FontAttributes = FontAttributes.Bold,
            VerticalOptions = LayoutOptions.Center
        }, 1, 0);
        return row;
    }

    private async void NewHorseButton_Clicked(object? sender, EventArgs e) =>
        await Shell.Current.GoToAsync("//MainPage");

    private async void HistoryButton_Clicked(object? sender, EventArgs e) =>
        await Shell.Current.GoToAsync("//HistoryPage");

    private async void StatisticsButton_Clicked(object? sender, EventArgs e) =>
        await Shell.Current.GoToAsync("//StatisticsPage");

    private async void ExpenseButton_Clicked(object? sender, EventArgs e) =>
        await Shell.Current.GoToAsync(nameof(ExpensesPage));
}
