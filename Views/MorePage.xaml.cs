namespace QaziCalculator.Views;

public partial class MorePage : ContentPage
{
    public MorePage()
    {
        InitializeComponent();
    }

    private async void QaziButton_Clicked(object? sender, EventArgs e) =>
        await Shell.Current.GoToAsync(nameof(QaziCompositionPage));

    private async void ExpensesButton_Clicked(object? sender, EventArgs e) =>
        await Shell.Current.GoToAsync(nameof(ExpensesPage));

    private async void ProductsButton_Clicked(object? sender, EventArgs e) =>
        await Shell.Current.GoToAsync(nameof(ProductsPage));

    private async void ReportsButton_Clicked(object? sender, EventArgs e) =>
        await Shell.Current.GoToAsync(nameof(ReportsPage));

    private async void SettingsButton_Clicked(object? sender, EventArgs e) =>
        await Shell.Current.GoToAsync(nameof(SettingsPage));
}
