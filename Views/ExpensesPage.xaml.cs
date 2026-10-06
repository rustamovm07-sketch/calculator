using System.Globalization;
using QaziCalculator.Data;
using QaziCalculator.Models;

namespace QaziCalculator.Views;

public partial class ExpensesPage : ContentPage
{
    private readonly DatabaseService _databaseService = new();
    private List<HorseBatch> _batches = [];
    private Expense? _selectedExpense;

    public ExpensesPage()
    {
        InitializeComponent();
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        await LoadDataAsync();
    }

    private async Task LoadDataAsync()
    {
        try
        {
            _batches = await _databaseService.GetHorseBatchesAsync();
            var allOption = new HorseBatch { Id = 0, Name = "Umumiy xarajat" };
            HorsePicker.ItemsSource = new[] { allOption }.Concat(_batches).ToList();
            HorsePicker.SelectedIndex = 0;

            var expenses = await _databaseService.GetExpensesAsync();
            ExpensesCollection.ItemsSource = expenses;
            var now = DateTime.Now;
            TodayTotalLabel.Text = $"{expenses.Where(x => x.CreatedAt.Date == now.Date).Sum(x => x.Amount):N0} so'm";
            MonthTotalLabel.Text = $"{expenses.Where(x => x.CreatedAt.Year == now.Year && x.CreatedAt.Month == now.Month).Sum(x => x.Amount):N0} so'm";
            AllTotalLabel.Text = $"{expenses.Sum(x => x.Amount):N0} so'm";
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(ex);
            await DisplayAlertAsync("Xatolik", "Xarajatlarni yuklab bo'lmadi.", "OK");
        }
    }

    private async void SaveButton_Clicked(object? sender, EventArgs e)
    {
        if (CategoryPicker.SelectedIndex < 0 ||
            string.IsNullOrWhiteSpace(NameEntry.Text) ||
            !TryParseAmount(AmountEntry.Text, out var amount) ||
            amount < 0)
        {
            await DisplayAlertAsync("Ma'lumotni tekshiring", "Kategoriya, nom va manfiy bo'lmagan summani kiriting.", "OK");
            return;
        }

        var expense = _selectedExpense ?? new Expense();
        expense.Category = CategoryPicker.Items[CategoryPicker.SelectedIndex];
        expense.Name = NameEntry.Text.Trim();
        expense.Amount = amount;
        expense.HorseBatchId = (HorsePicker.SelectedItem as HorseBatch)?.Id ?? 0;
        expense.Notes = NotesEditor.Text?.Trim() ?? string.Empty;

        try
        {
            await _databaseService.SaveExpenseAsync(expense);
            await ClearFormAsync();
            await LoadDataAsync();
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(ex);
            await DisplayAlertAsync("Xatolik", "Xarajatni saqlab bo'lmadi.", "OK");
        }
    }

    private void ExpensesCollection_SelectionChanged(object? sender, SelectionChangedEventArgs e)
    {
        _selectedExpense = e.CurrentSelection.OfType<Expense>().FirstOrDefault();
        if (_selectedExpense is null)
        {
            SelectionLabel.Text = "Tahrirlash uchun xarajatni tanlang.";
            return;
        }

        CategoryPicker.SelectedItem = _selectedExpense.Category;
        NameEntry.Text = _selectedExpense.Name;
        AmountEntry.Text = _selectedExpense.Amount.ToString(CultureInfo.CurrentCulture);
        HorsePicker.SelectedItem = ((List<HorseBatch>)HorsePicker.ItemsSource!)
            .FirstOrDefault(x => x.Id == _selectedExpense.HorseBatchId);
        NotesEditor.Text = _selectedExpense.Notes;
        SelectionLabel.Text = $"Tahrirlanmoqda: {_selectedExpense.CreatedAt:dd.MM.yyyy}";
    }

    private async void DeleteButton_Clicked(object? sender, EventArgs e)
    {
        if (_selectedExpense is null)
        {
            await DisplayAlertAsync("Yozuv tanlanmagan", "O'chirish uchun xarajatni tanlang.", "OK");
            return;
        }

        if (!await DisplayAlertAsync("Xarajatni o'chirish", "Tanlangan xarajat o'chirilsinmi?", "O'chirish", "Bekor qilish"))
            return;

        try
        {
            await _databaseService.DeleteExpenseAsync(_selectedExpense);
            await ClearFormAsync();
            await LoadDataAsync();
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(ex);
            await DisplayAlertAsync("Xatolik", "Xarajatni o'chirib bo'lmadi.", "OK");
        }
    }

    private async void ClearButton_Clicked(object? sender, EventArgs e) =>
        await ClearFormAsync();

    private Task ClearFormAsync()
    {
        _selectedExpense = null;
        CategoryPicker.SelectedIndex = -1;
        NameEntry.Text = string.Empty;
        AmountEntry.Text = string.Empty;
        HorsePicker.SelectedIndex = 0;
        NotesEditor.Text = string.Empty;
        ExpensesCollection.SelectedItem = null;
        SelectionLabel.Text = "Tahrirlash uchun xarajatni tanlang.";
        return Task.CompletedTask;
    }

    private static bool TryParseAmount(string? text, out decimal amount) =>
        decimal.TryParse(text, NumberStyles.Number, CultureInfo.CurrentCulture, out amount) ||
        decimal.TryParse(text, NumberStyles.Number, CultureInfo.InvariantCulture, out amount);
}
