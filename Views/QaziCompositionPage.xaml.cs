using System.Globalization;
using QaziCalculator.Data;
using QaziCalculator.Models;
using QaziCalculator.Services;

namespace QaziCalculator.Views;

public partial class QaziCompositionPage : ContentPage
{
    private readonly DatabaseService _databaseService = new();
    private readonly QaziPredictionEngine _predictionEngine = new();
    private QaziComposition? _selectedComposition;
    private List<HorseBatch> _batches = [];

    public QaziCompositionPage()
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
            HorsePicker.ItemsSource = _batches;
            CompositionCollection.ItemsSource =
                await _databaseService.GetQaziCompositionsAsync();
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(ex);
            await DisplayAlertAsync("Xatolik", "Qazi yozuvlarini yuklab bo'lmadi.", "OK");
        }
    }

    private async void SaveButton_Clicked(object? sender, EventArgs e)
    {
        if (HorsePicker.SelectedItem is not HorseBatch batch)
        {
            await DisplayAlertAsync("Ot tanlanmagan", "Qazi kuzatuviga tegishli otni tanlang.", "OK");
            return;
        }

        if (!TryReadNonNegative(TotalQaziEntry.Text, out var totalQaziKg) ||
            !TryReadNonNegative(MeatEntry.Text, out var meatKg) ||
            !TryReadNonNegative(FatEntry.Text, out var fatKg) ||
            totalQaziKg <= 0 ||
            meatKg + fatKg > totalQaziKg)
        {
            await DisplayAlertAsync(
                "Qiymatlarni tekshiring",
                "Jami qazi 0 dan katta bo'lsin; go'sht va yog' manfiy bo'lmasin va ularning yig'indisi jami qazini oshirmasin.",
                "OK");
            return;
        }

        var composition = _selectedComposition ?? new QaziComposition();
        composition.HorseBatchId = batch.Id;
        composition.TotalQaziKg = totalQaziKg;
        composition.MeatKg = meatKg;
        composition.FatKg = fatKg;
        composition.Notes = NotesEditor.Text?.Trim() ?? string.Empty;

        try
        {
            await _databaseService.SaveQaziCompositionAsync(composition);
            await ClearFormAsync();
            await LoadDataAsync();
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(ex);
            await DisplayAlertAsync("Xatolik", "Qazi kuzatuvini saqlab bo'lmadi.", "OK");
        }
    }

    private void CompositionCollection_SelectionChanged(object? sender, SelectionChangedEventArgs e)
    {
        _selectedComposition = e.CurrentSelection.OfType<QaziComposition>().FirstOrDefault();
        if (_selectedComposition is null)
        {
            SelectionLabel.Text = "Ro'yxatdan yozuv tanlab tahrirlang yoki o'chiring.";
            return;
        }

        HorsePicker.SelectedItem = _batches.FirstOrDefault(
            batch => batch.Id == _selectedComposition.HorseBatchId);
        TotalQaziEntry.Text = _selectedComposition.TotalQaziKg.ToString(CultureInfo.CurrentCulture);
        MeatEntry.Text = _selectedComposition.MeatKg.ToString(CultureInfo.CurrentCulture);
        FatEntry.Text = _selectedComposition.FatKg.ToString(CultureInfo.CurrentCulture);
        NotesEditor.Text = _selectedComposition.Notes;
        SelectionLabel.Text = $"Tahrirlanmoqda: {_selectedComposition.CreatedAt:dd.MM.yyyy}";
    }

    private async void DeleteButton_Clicked(object? sender, EventArgs e)
    {
        if (_selectedComposition is null)
        {
            await DisplayAlertAsync("Yozuv tanlanmagan", "O'chirish uchun qazi yozuvini tanlang.", "OK");
            return;
        }

        var confirmed = await DisplayAlertAsync(
            "Yozuvni o'chirish",
            "Tanlangan qazi kuzatuvi o'chirilsinmi?",
            "O'chirish",
            "Bekor qilish");
        if (!confirmed)
            return;

        try
        {
            await _databaseService.DeleteQaziCompositionAsync(_selectedComposition);
            await ClearFormAsync();
            await LoadDataAsync();
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(ex);
            await DisplayAlertAsync("Xatolik", "Qazi kuzatuvini o'chirib bo'lmadi.", "OK");
        }
    }

    private async void PredictButton_Clicked(object? sender, EventArgs e)
    {
        if (!TryReadNonNegative(TargetQaziEntry.Text, out var targetQaziKg) ||
            !double.IsFinite(targetQaziKg) ||
            targetQaziKg <= 0)
        {
            await DisplayAlertAsync("Qiymat xatoligi", "Maqsad qazi miqdorini 0 dan katta kiriting.", "OK");
            return;
        }

        try
        {
            var records = await _databaseService.GetQaziCompositionsAsync();
            var prediction = _predictionEngine.Predict(records, targetQaziKg);
            PredictionLabel.Text = prediction.HasEnoughData
                ? $"Prognoz (real tarkib tarixidan): go'sht {prediction.PredictedMeatKg:N2} kg, yog' {prediction.PredictedFatKg:N2} kg. Namuna: {prediction.SampleCount}; ishonchlilik: {prediction.ReliabilityLevel} ({prediction.ConfidenceScore:N0}%); SD: go'sht {prediction.MeatStandardDeviation:N3}, yog' {prediction.FatStandardDeviation:N3} kg/kg."
                : $"Prognoz uchun ma'lumot yetarli emas. Haqiqiy tarkib yozuvlari: {prediction.SampleCount}/5.";
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(ex);
            await DisplayAlertAsync("Xatolik", "Qazi tarixiy tahlilini hisoblab bo'lmadi.", "OK");
        }
    }

    private async void ClearButton_Clicked(object? sender, EventArgs e) =>
        await ClearFormAsync();

    private Task ClearFormAsync()
    {
        _selectedComposition = null;
        HorsePicker.SelectedItem = null;
        TotalQaziEntry.Text = string.Empty;
        MeatEntry.Text = string.Empty;
        FatEntry.Text = string.Empty;
        NotesEditor.Text = string.Empty;
        CompositionCollection.SelectedItem = null;
        SelectionLabel.Text = "Ro'yxatdan yozuv tanlab tahrirlang yoki o'chiring.";
        return Task.CompletedTask;
    }

    private static bool TryReadNonNegative(string? text, out double value)
    {
        var parsed = double.TryParse(text, NumberStyles.Float, CultureInfo.CurrentCulture, out value) ||
            double.TryParse(text, NumberStyles.Float, CultureInfo.InvariantCulture, out value);
        return parsed && double.IsFinite(value) && value >= 0;
    }
}
