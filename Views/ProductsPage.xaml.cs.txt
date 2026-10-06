using System.Globalization;
using QaziCalculator.Data;
using QaziCalculator.Models;

namespace QaziCalculator.Views;

public partial class ProductsPage : ContentPage
{
    private readonly DatabaseService _databaseService = new();
    private Product? _selectedProduct;

    public ProductsPage()
    {
        InitializeComponent();
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        await LoadProductsAsync();
    }

    private async Task LoadProductsAsync()
    {
        try
        {
            ProductsCollection.ItemsSource = await _databaseService.GetProductsAsync();
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(ex);
            await DisplayAlertAsync("Xatolik", "Mahsulotlarni yuklab bo'lmadi.", "OK");
        }
    }

    private async void SaveButton_Clicked(object? sender, EventArgs e)
    {
        if (string.IsNullOrWhiteSpace(NameEntry.Text) ||
            !TryParseNonNegativeDouble(StockEntry.Text, out var stock) ||
            !TryParseNonNegativeDecimal(PriceEntry.Text, out var price))
        {
            await DisplayAlertAsync("Ma'lumotni tekshiring", "Nom kiriting va zaxira hamda narxni manfiy bo'lmagan son qilib belgilang.", "OK");
            return;
        }

        var product = _selectedProduct ?? new Product();
        product.Name = NameEntry.Text.Trim();
        product.Unit = string.IsNullOrWhiteSpace(UnitEntry.Text) ? "kg" : UnitEntry.Text.Trim();
        product.StockQuantity = stock;
        product.SalePrice = price;
        product.IsActive = ActiveCheckBox.IsChecked;
        product.Notes = NotesEditor.Text?.Trim() ?? string.Empty;

        try
        {
            await _databaseService.SaveProductAsync(product);
            await ClearFormAsync();
            await LoadProductsAsync();
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(ex);
            await DisplayAlertAsync("Xatolik", "Mahsulotni saqlab bo'lmadi.", "OK");
        }
    }

    private void ProductsCollection_SelectionChanged(object? sender, SelectionChangedEventArgs e)
    {
        _selectedProduct = e.CurrentSelection.OfType<Product>().FirstOrDefault();
        if (_selectedProduct is null)
        {
            SelectionLabel.Text = "Tahrirlash uchun mahsulotni tanlang.";
            return;
        }

        NameEntry.Text = _selectedProduct.Name;
        UnitEntry.Text = _selectedProduct.Unit;
        StockEntry.Text = _selectedProduct.StockQuantity.ToString(CultureInfo.CurrentCulture);
        PriceEntry.Text = _selectedProduct.SalePrice.ToString(CultureInfo.CurrentCulture);
        ActiveCheckBox.IsChecked = _selectedProduct.IsActive;
        NotesEditor.Text = _selectedProduct.Notes;
        SelectionLabel.Text = "Mahsulot tahrirlanmoqda.";
    }

    private async void DeleteButton_Clicked(object? sender, EventArgs e)
    {
        if (_selectedProduct is null)
        {
            await DisplayAlertAsync("Mahsulot tanlanmagan", "O'chirish uchun mahsulotni tanlang.", "OK");
            return;
        }

        if (!await DisplayAlertAsync("Mahsulotni o'chirish", "Tanlangan mahsulot o'chirilsinmi?", "O'chirish", "Bekor qilish"))
            return;

        try
        {
            await _databaseService.DeleteProductAsync(_selectedProduct);
            await ClearFormAsync();
            await LoadProductsAsync();
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(ex);
            await DisplayAlertAsync("Xatolik", "Mahsulotni o'chirib bo'lmadi.", "OK");
        }
    }

    private async void ClearButton_Clicked(object? sender, EventArgs e) =>
        await ClearFormAsync();

    private Task ClearFormAsync()
    {
        _selectedProduct = null;
        NameEntry.Text = string.Empty;
        UnitEntry.Text = "kg";
        StockEntry.Text = string.Empty;
        PriceEntry.Text = string.Empty;
        ActiveCheckBox.IsChecked = true;
        NotesEditor.Text = string.Empty;
        ProductsCollection.SelectedItem = null;
        SelectionLabel.Text = "Tahrirlash uchun mahsulotni tanlang.";
        return Task.CompletedTask;
    }

    private static bool TryParseNonNegativeDouble(string? text, out double value)
    {
        var parsed = double.TryParse(text, NumberStyles.Float, CultureInfo.CurrentCulture, out value) ||
            double.TryParse(text, NumberStyles.Float, CultureInfo.InvariantCulture, out value);
        return parsed && double.IsFinite(value) && value >= 0;
    }

    private static bool TryParseNonNegativeDecimal(string? text, out decimal value) =>
        decimal.TryParse(text, NumberStyles.Number, CultureInfo.CurrentCulture, out value) && value >= 0 ||
        decimal.TryParse(text, NumberStyles.Number, CultureInfo.InvariantCulture, out value) && value >= 0;
}
