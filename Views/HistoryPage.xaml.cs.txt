using QaziCalculator.Data;
using QaziCalculator.Models;

namespace QaziCalculator.Views;

public partial class HistoryPage : ContentPage
{
    private readonly DatabaseService _databaseService = new();
    private List<HorseBatch> _batches = [];
    private string? _searchText;

    public HistoryPage()
    {
        InitializeComponent();
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();

        await LoadHistoryAsync();
    }

    private async Task LoadHistoryAsync()
    {
        try
        {
            _batches =
                await _databaseService
                    .GetHorseBatchesAsync();

            CountLabel.Text =
                $"{_batches.Count} ta ot";
            ApplySearch();
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(ex);
            await DisplayAlertAsync(
                "Xatolik",
                "Saqlangan tarixni yuklab bo'lmadi.",
                "OK");
        }
    }

    private async void RefreshButton_Clicked(
        object? sender,
        EventArgs e)
    {
        await LoadHistoryAsync();
    }

    private void HistorySearchBar_TextChanged(
        object? sender,
        TextChangedEventArgs e)
    {
        _searchText = e.NewTextValue;
        ApplySearch();
    }

    private void ApplySearch()
    {
        var searchText = _searchText?.Trim();
        HistoryCollectionView.ItemsSource = string.IsNullOrEmpty(searchText)
            ? _batches
            : _batches
                .Where(batch => batch.Name.Contains(
                    searchText,
                    StringComparison.CurrentCultureIgnoreCase))
                .ToList();
    }

    private async void HistoryCollectionView_SelectionChanged(
        object? sender,
        SelectionChangedEventArgs e)
    {
        var batch = e.CurrentSelection
            .OfType<HorseBatch>()
            .FirstOrDefault();

        if (batch is null)
            return;

        HistoryCollectionView.SelectedItem = null;

        await Shell.Current.GoToAsync(
            nameof(HorseDetailsPage),
            true,
            new Dictionary<string, object>
            {
                ["HorseBatchId"] = batch.Id
            });
    }

    private async void HistoryRefreshView_Refreshing(
        object? sender,
        EventArgs e)
    {
        try
        {
            await LoadHistoryAsync();
        }
        finally
        {
            HistoryRefreshView.IsRefreshing =
                false;
        }
    }
}
