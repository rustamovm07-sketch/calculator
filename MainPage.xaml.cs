using QaziCalculator.Data;
using QaziCalculator.Models;
using QaziCalculator.Services;

namespace QaziCalculator;

public partial class MainPage : ContentPage
{
    private readonly CalculationEngine _calculationEngine = new();
    private readonly DatabaseService _databaseService = new();
    private readonly PredictionEngine _predictionEngine = new();
    private readonly QaziPredictionEngine _qaziPredictionEngine = new();

    private ProcessingResult? _currentResult;
    private WeightPrediction? _currentPrediction;
    private QaziPrediction? _currentQaziPrediction;
    private bool _isCurrentResultSaved;

    public MainPage()
    {
        InitializeComponent();
    }

    private async void CalculateButton_Clicked(
        object? sender,
        EventArgs e)
    {
        _currentResult = null;
        _currentPrediction = null;
        _currentQaziPrediction = null;
        _isCurrentResultSaved = false;
        ResultCard.IsVisible = false;
        PredictionCard.IsVisible = false;

        if (!TryReadInput(
                out var result,
                out var errorMessage))
        {
            await DisplayAlertAsync(
                "Xatolik",
                errorMessage,
                "OK");

            return;
        }

        if (!_calculationEngine.ValidateResult(
                result,
                out errorMessage))
        {
            await DisplayAlertAsync(
                "Xatolik",
                errorMessage,
                "OK");

            return;
        }

        _currentResult = result;
        _isCurrentResultSaved = false;

        await CalculatePredictionsAsync(
            result.LiveWeightKg);

        ShowResult(result);
    }

    private async Task CalculatePredictionsAsync(
        double targetWeightKg)
    {
        var allResults =
            await _databaseService
                .GetAllProcessingResultsAsync();

        _currentPrediction =
            _predictionEngine.Predict(
                allResults,
                targetWeightKg);

        var qaziCompositions =
            await _databaseService
                .GetQaziCompositionsAsync();

        /*
         * Hozircha QaziPredictionEngine
         * qazini mustaqil ravishda hisoblamaydi.
         *
         * Avval real tarixiy qazi ma'lumotlaridan
         * 1 kg qazi tarkibi o‘rganiladi.
         *
         * Keyingi bosqichda bu modelga
         * yangi ot uchun hisoblangan QaziKg
         * uzatiladi.
         */
        _currentQaziPrediction =
            qaziCompositions.Count >= 5
                ? _qaziPredictionEngine.Predict(
                    qaziCompositions,
                    1.0)
                : QaziPrediction.NotEnoughData(
                    1.0,
                    qaziCompositions.Count);
    }

    private async void SaveButton_Clicked(
        object? sender,
        EventArgs e)
    {
        if (_currentResult is null)
        {
            await DisplayAlertAsync(
                "Ma'lumot yo‘q",
                "Avval natijani hisoblang.",
                "OK");

            return;
        }

        if (_isCurrentResultSaved)
        {
            await DisplayAlertAsync(
                "Allaqachon saqlangan",
                "Bu natija avval saqlangan. Yangi hisoblash yarating.",
                "OK");
            return;
        }

        if (!_calculationEngine.ValidateResult(
                _currentResult,
                out var errorMessage))
        {
            await DisplayAlertAsync(
                "Xatolik",
                errorMessage,
                "OK");

            return;
        }

        var horseBatch =
            new HorseBatch
            {
                Name =
                    string.IsNullOrWhiteSpace(
                        HorseNameEntry.Text)
                        ? $"Ot-{DateTime.Now:yyyyMMdd-HHmmss}"
                        : HorseNameEntry.Text.Trim(),

                CreatedAt =
                    DateTime.Now,

                LiveWeightKg =
                    _currentResult.LiveWeightKg,

                PurchasePricePerKg =
                    GetPurchasePrice(),

                CleanMeatKg =
                    _currentResult.CleanMeatKg,

                FatKg =
                    _currentResult.FatKg,

                BoneKg =
                    _currentResult.BoneKg,

                TendonKg =
                    _currentResult.TendonKg,

                KachalkaKg =
                    _currentResult.KachalkaKg,

                TarashKg =
                    _currentResult.TarashKg,

                WasteKg =
                    _currentResult.WasteKg,

                QaziKg =
                    _currentResult.QaziKg,

                IntestineKg = 0,

                OtherKg = 0,

                Notes =
                    NotesEditor.Text ??
                    string.Empty
            };

        try
        {
            await _databaseService
                .SaveHorseBatchAndProcessingResultAsync(
                    horseBatch,
                    _currentResult);
            _isCurrentResultSaved = true;
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(ex);
            await DisplayAlertAsync(
                "Xatolik",
                "Qayta ishlash natijasini saqlab bo'lmadi. Ma'lumotlar bazasini tekshirib, qayta urinib ko'ring.",
                "OK");
            return;
        }

        await DisplayAlertAsync(
            "Saqlandi",
            "Real qayta ishlash natijalari bazaga saqlandi.",
            "OK");

    }

    private bool TryReadInput(
        out ProcessingResult result,
        out string errorMessage)
    {
        result =
            new ProcessingResult();

        errorMessage =
            string.Empty;

        if (!TryParseDouble(
                LiveWeightEntry.Text,
                out var liveWeightKg))
        {
            errorMessage =
                "Otning tirik vaznini to‘g‘ri kiriting.";

            return false;
        }

        if (liveWeightKg <= 0)
        {
            errorMessage =
                "Ot vazni 0 dan katta bo‘lishi kerak.";

            return false;
        }

        if (!TryParseDecimal(
                PurchasePriceEntry.Text,
                out var purchasePrice))
        {
            errorMessage =
                "1 kg xarid narxini to‘g‘ri kiriting.";

            return false;
        }

        if (purchasePrice < 0)
        {
            errorMessage =
                "Xarid narxi manfiy bo‘lishi mumkin emas.";

            return false;
        }

        if (!TryParseDoubleOrZero(
                CleanMeatEntry.Text,
                out var cleanMeatKg))
        {
            errorMessage =
                "Toza go‘sht vaznini to‘g‘ri kiriting.";

            return false;
        }

        if (!TryParseDoubleOrZero(
                FatEntry.Text,
                out var fatKg))
        {
            errorMessage =
                "Yog‘ vaznini to‘g‘ri kiriting.";

            return false;
        }

        if (!TryParseDoubleOrZero(
                BoneEntry.Text,
                out var boneKg))
        {
            errorMessage =
                "Suyak vaznini to‘g‘ri kiriting.";

            return false;
        }

        if (!TryParseDoubleOrZero(
                TendonEntry.Text,
                out var tendonKg))
        {
            errorMessage =
                "Pay vaznini to‘g‘ri kiriting.";

            return false;
        }

        if (!TryParseDoubleOrZero(
                KachalkaEntry.Text,
                out var kachalkaKg))
        {
            errorMessage =
                "Kachalka vaznini to‘g‘ri kiriting.";

            return false;
        }

        if (!TryParseDoubleOrZero(
                TarashEntry.Text,
                out var tarashKg))
        {
            errorMessage =
                "Tarash vaznini to‘g‘ri kiriting.";

            return false;
        }

        if (!TryParseDoubleOrZero(
                WasteEntry.Text,
                out var wasteKg))
        {
            errorMessage =
                "Chiqindi vaznini to‘g‘ri kiriting.";

            return false;
        }

        result =
            new ProcessingResult
            {
                LiveWeightKg =
                    liveWeightKg,

                CleanMeatKg =
                    cleanMeatKg,

                FatKg =
                    fatKg,

                BoneKg =
                    boneKg,

                TendonKg =
                    tendonKg,

                KachalkaKg =
                    kachalkaKg,

                TarashKg =
                    tarashKg,

                WasteKg =
                    wasteKg,

                QaziKg = 0,

                IntestineKg = 0,

                OtherKg = 0
            };

        return true;
    }

    private void ShowResult(
        ProcessingResult result)
    {
        var purchaseCost =
            (decimal)result.LiveWeightKg *
            GetPurchasePrice();

        var totalMeasured =
            _calculationEngine
                .CalculateTotalMeasured(
                    result);

        var unaccounted =
            _calculationEngine
                .CalculateUnaccountedWeight(
                    result);

        WeightResultLabel.Text =
            $"{result.LiveWeightKg:N2} kg";

        PurchaseCostResultLabel.Text =
            $"{purchaseCost:N0} so‘m";

        CleanMeatResultLabel.Text =
            FormatKgPercent(
                result.CleanMeatKg,
                result.CleanMeatPercent);

        FatResultLabel.Text =
            FormatKgPercent(
                result.FatKg,
                result.FatPercent);

        BoneResultLabel.Text =
            FormatKgPercent(
                result.BoneKg,
                result.BonePercent);

        TendonResultLabel.Text =
            FormatKgPercent(
                result.TendonKg,
                result.TendonPercent);

        KachalkaResultLabel.Text =
            FormatKgPercent(
                result.KachalkaKg,
                result.KachalkaPercent);

        TarashResultLabel.Text =
            FormatKgPercent(
                result.TarashKg,
                result.TarashPercent);

        WasteResultLabel.Text =
            FormatKgPercent(
                result.WasteKg,
                result.WastePercent);

        TotalOutputResultLabel.Text =
            $"{totalMeasured:N2} kg / " +
            $"{result.TotalMeasuredPercent:N2}%";

        UnaccountedResultLabel.Text =
            $"{unaccounted:N2} kg";

        ShowQaziPrediction();
        ShowProductionPrediction(result.LiveWeightKg);

        ResultCard.IsVisible =
            true;
        PredictionCard.IsVisible = true;
    }

    private void ShowProductionPrediction(double targetWeightKg)
    {
        if (_currentPrediction is null || !_currentPrediction.HasEnoughData)
        {
            PredictionSummaryLabel.Text =
                "Prognoz uchun ma'lumot yetarli emas. Kamida 5 ta real kuzatuv kerak.";
            PredictedCleanMeatLabel.Text = "Prognoz uchun ma'lumot yetarli emas.";
            PredictedFatLabel.Text = "Prognoz uchun ma'lumot yetarli emas.";
            PredictedBoneLabel.Text = "Prognoz uchun ma'lumot yetarli emas.";
            PredictedTendonLabel.Text = "Prognoz uchun ma'lumot yetarli emas.";
            PredictedKachalkaLabel.Text = "Prognoz uchun ma'lumot yetarli emas.";
            PredictedTarashLabel.Text = "Prognoz uchun ma'lumot yetarli emas.";
            PredictedWasteLabel.Text = "Prognoz uchun ma'lumot yetarli emas.";
            return;
        }

        PredictionSummaryLabel.Text =
            $"Maqsad: {targetWeightKg:N2} kg | Tarixdagi real kuzatuvlar: {_currentPrediction.SampleCount}. Prognoz kafolat emas.";
        PredictedCleanMeatLabel.Text = FormatPrediction(_currentPrediction.CleanMeat, targetWeightKg);
        PredictedFatLabel.Text = FormatPrediction(_currentPrediction.Fat, targetWeightKg);
        PredictedBoneLabel.Text = FormatPrediction(_currentPrediction.Bone, targetWeightKg);
        PredictedTendonLabel.Text = FormatPrediction(_currentPrediction.Tendon, targetWeightKg);
        PredictedKachalkaLabel.Text = FormatPrediction(_currentPrediction.Kachalka, targetWeightKg);
        PredictedTarashLabel.Text = FormatPrediction(_currentPrediction.Tarash, targetWeightKg);
        PredictedWasteLabel.Text = FormatPrediction(_currentPrediction.Waste, targetWeightKg);
    }

    private static string FormatPrediction(
        PredictionMetric metric,
        double targetWeightKg)
    {
        if (!metric.HasEnoughData)
            return $"Ma'lumot yetarli emas ({metric.SampleCount}/5)";

        return
            $"{metric.PredictKg(targetWeightKg):N2} kg ({metric.PredictedPercent:N2}%)\n" +
            $"SD {metric.StandardDeviation:N2} p.p. · {metric.ReliabilityLevel}";
    }

    private void ShowQaziPrediction()
    {
        if (_currentPrediction is null)
        {
            QaziResultLabel.Text =
                "Prognoz uchun ma’lumot kerak";

            QaziInfoLabel.Text =
                "Hali real tarixiy ma’lumot yetarli emas.";

            return;
        }

        /*
         * Hozirgi bosqichda QaziPredictionEngine
         * faqat qazi tarkibini o‘rganadi.
         *
         * Yangi ot uchun qazi miqdorini hisoblash
         * hali hardcode qilinmagan.
         *
         * Shuning uchun noto‘g‘ri qazi foizi chiqarish
         * o‘rniga foydalanuvchiga ma'lumot yetarli
         * emasligini ko‘rsatamiz.
         */
        QaziResultLabel.Text =
            "Qazi modeli tayyorlanmoqda";

        if (_currentQaziPrediction is null ||
            !_currentQaziPrediction.HasEnoughData)
        {
            var count =
                _currentQaziPrediction?.SampleCount ?? 0;

            QaziInfoLabel.Text =
                $"{count} ta real qazi tarkibi mavjud. " +
                "Kamida 5 ta real qazi partiyasi " +
                "kerak.";

            return;
        }

        QaziResultLabel.Text =
            "1 kg qazi tarkibi";

        QaziInfoLabel.Text =
            $"Go‘sht: " +
            $"{_currentQaziPrediction.MeatPerQaziKg:N3} kg | " +
            $"Yog‘: " +
            $"{_currentQaziPrediction.FatPerQaziKg:N3} kg | " +
            $"Ishonchlilik: " +
            $"{_currentQaziPrediction.ConfidenceScore:N0}%";
    }

    private decimal GetPurchasePrice()
    {
        return TryParseDecimal(
            PurchasePriceEntry.Text,
            out var price)
            ? price
            : 0;
    }

    private static string FormatKgPercent(
        double kilograms,
        double percentage)
    {
        return
            $"{kilograms:N2} kg / " +
            $"{percentage:N2}%";
    }

    private static bool TryParseDouble(
        string? text,
        out double value)
    {
        return double.TryParse(
            text,
            System.Globalization.NumberStyles.Float,
            System.Globalization.CultureInfo.CurrentCulture,
            out value);
    }

    private static bool TryParseDoubleOrZero(
        string? text,
        out double value)
    {
        if (string.IsNullOrWhiteSpace(text))
        {
            value = 0;
            return true;
        }

        return TryParseDouble(
            text,
            out value);
    }

    private static bool TryParseDecimal(
        string? text,
        out decimal value)
    {
        return decimal.TryParse(
            text,
            System.Globalization.NumberStyles.Number,
            System.Globalization.CultureInfo.CurrentCulture,
            out value);
    }
}
