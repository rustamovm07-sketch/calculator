using System.Linq;
using QaziCalculator.Data;
using QaziCalculator.Models;

namespace QaziCalculator.Views;

[QueryProperty(nameof(HorseBatchId), "HorseBatchId")]
public partial class HorseDetailsPage : ContentPage
{
    private readonly DatabaseService _databaseService = new();
    private int _horseBatchId;

    public HorseDetailsPage()
    {
        InitializeComponent();
    }

    public int HorseBatchId
    {
        get => _horseBatchId;
        set
        {
            _horseBatchId = value;
            _ = LoadHorseAsync(value);
        }
    }

    private async Task LoadHorseAsync(int horseBatchId)
    {
        try
        {
            var batch = await _databaseService.GetHorseBatchAsync(horseBatchId);
            if (batch is null)
            {
                await DisplayAlertAsync(
                    "Ma'lumot topilmadi",
                    "Ushbu ot ma'lumoti topilmadi.",
                    "OK");

                await Shell.Current.GoToAsync("..");
                return;
            }

            var qaziComposition =
                (await _databaseService.GetQaziCompositionsAsync(horseBatchId))
                .FirstOrDefault();

            HorseNameLabel.Text = batch.Name;
            HorseDateLabel.Text = $"Yaratilgan: {batch.CreatedAt:dd.MM.yyyy HH:mm}";
            LiveWeightLabel.Text = $"{batch.LiveWeightKg:N2} kg";
            PurchasePriceLabel.Text = $"{batch.PurchasePricePerKg:N0} so'm/kg";
            TotalCostLabel.Text = $"{batch.TotalPurchaseCost:N0} so'm";
            TotalMeasuredLabel.Text = $"{batch.TotalMeasuredKg:N2} kg ({batch.TotalMeasuredPercent:N2}%)";
            UnaccountedWeightLabel.Text = $"{batch.UnaccountedWeightKg:N2} kg";
            QaziStatusLabel.Text = batch.QaziKg > 0 ? $"{batch.QaziKg:N2} kg" : "Hali aniqlanmagan";

            SetMeasurementLabel(CleanMeatLabel, "Toza go'sht", batch.CleanMeatKg, batch.CleanMeatPercent);
            SetMeasurementLabel(FatLabel, "Yog'", batch.FatKg, batch.FatPercent);
            SetMeasurementLabel(BoneLabel, "Suyak", batch.BoneKg, batch.BonePercent);
            SetMeasurementLabel(TendonLabel, "Pay", batch.TendonKg, batch.TendonPercent);
            SetMeasurementLabel(KachalkaLabel, "Kachalka", batch.KachalkaKg, batch.KachalkaPercent);
            SetMeasurementLabel(TarashLabel, "Tarash", batch.TarashKg, batch.TarashPercent);
            SetMeasurementLabel(WasteLabel, "Chiqindi", batch.WasteKg, batch.WastePercent);

            if (qaziComposition is null)
            {
                QaziCompositionStatusLabel.Text = "Hali aniqlanmagan";
                QaziCompositionDetailsLabel.Text = "Bu ot uchun real qazi tarkibi mavjud emas.";
            }
            else
            {
                QaziCompositionStatusLabel.Text = "Mavjud";
                QaziCompositionDetailsLabel.Text =
                    $"TotalQaziKg: {qaziComposition.TotalQaziKg:N2} kg | " +
                    $"MeatKg: {qaziComposition.MeatKg:N2} kg ({qaziComposition.MeatPercent:N1}%) | " +
                    $"FatKg: {qaziComposition.FatKg:N2} kg ({qaziComposition.FatPercent:N1}%)";
            }

            NotesLabel.Text = string.IsNullOrWhiteSpace(batch.Notes) ? "-" : batch.Notes;
            ProcessingDateLabel.Text = batch.CreatedAt.ToString("dd.MM.yyyy HH:mm");
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(ex);
            await DisplayAlertAsync(
                "Xatolik",
                "Ot ma'lumotini yuklab bo'lmadi.",
                "OK");
        }
    }

    private static void SetMeasurementLabel(
        Label label,
        string title,
        double kgValue,
        double percentValue)
    {
        label.Text = $"{kgValue:N2} kg ({percentValue:N1}%)";
    }
}
