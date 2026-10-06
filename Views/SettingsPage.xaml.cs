using QaziCalculator.Data;
using QaziCalculator.Services;

namespace QaziCalculator.Views;

public partial class SettingsPage : ContentPage
{
    private readonly DatabaseService _databaseService = new();
    private readonly BackupService _backupService;

    public SettingsPage()
    {
        InitializeComponent();
        _backupService = new BackupService(_databaseService);
        VersionLabel.Text = $"Versiya: {AppInfo.Current.VersionString}";
        UpdateThemeButtons();
    }

    protected override async void OnAppearing()
    {
        base.OnAppearing();
        UpdateThemeButtons();
        await RefreshDatabaseInfoAsync();
    }

    private void ThemeModeButton_Clicked(object? sender, EventArgs e)
    {
        if (sender is not Button { CommandParameter: string mode } ||
            Application.Current is null)
            return;

        AppThemeService.SetTheme(Application.Current, mode);
        UpdateThemeButtons();
    }

    private void UpdateThemeButtons()
    {
        var mode = AppThemeService.CurrentMode;
        UpdateThemeButton(SystemThemeButton, mode == "System");
        UpdateThemeButton(LightThemeButton, mode == "Light");
        UpdateThemeButton(DarkThemeButton, mode == "Dark");
    }

    private static void UpdateThemeButton(Button button, bool isSelected)
    {
        button.BackgroundColor = isSelected
            ? Color.FromArgb("#8B1E2D")
            : Application.Current?.RequestedTheme == AppTheme.Dark
                ? Color.FromArgb("#29292F")
                : Color.FromArgb("#EFEFF2");
        button.TextColor = isSelected
            ? Colors.White
            : Application.Current?.RequestedTheme == AppTheme.Dark
                ? Colors.White
                : Color.FromArgb("#25252A");
    }

    private async void BackupButton_Clicked(object? sender, EventArgs e)
    {
        try
        {
            var path = await _backupService.CreateBackupAsync();
            await Share.Default.RequestAsync(new ShareFileRequest
            {
                Title = "Adenalin Calculator zaxirasi",
                File = new ShareFile(path)
            });
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(ex);
            await DisplayAlertAsync("Xatolik", "Zaxira nusxasini yaratib bo'lmadi.", "OK");
        }
    }

    private async void RestoreButton_Clicked(object? sender, EventArgs e)
    {
        var confirmed = await DisplayAlertAsync(
            "Zaxiradan tiklash",
            "Tanlangan zaxira yozuvlari mavjud ma'lumotlarga qo'shiladi. Davom etilsinmi?",
            "Davom etish",
            "Bekor qilish");
        if (!confirmed)
            return;

        try
        {
            var file = await FilePicker.Default.PickAsync(new PickOptions
            {
                PickerTitle = "Adenalin Calculator JSON zaxirasini tanlang"
            });
            if (file is null)
                return;

            var imported = await _backupService.ImportBackupAsync(file);
            await DisplayAlertAsync(
                imported ? "Tiklandi" : "Zaxira avval tiklangan",
                imported
                    ? "Zaxira yozuvlari mavjud ma'lumotlar saqlangan holda qo'shildi."
                    : "Ushbu zaxira fayli oldin tiklangan, takroriy yozuvlar qo'shilmadi.",
                "OK");
            await RefreshDatabaseInfoAsync();
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(ex);
            await DisplayAlertAsync(
                "Xatolik",
                "Zaxira faylini tekshirish yoki tiklash amalga oshmadi. Mavjud ma'lumotlar o'zgartirilmadi.",
                "OK");
        }
    }

    private async void DeleteAllButton_Clicked(object? sender, EventArgs e)
    {
        var confirmed = await DisplayAlertAsync(
            "Barcha ma'lumotlarni o'chirish",
            "Bu amal qaytarilmaydi. Davom etishdan oldin zaxira borligini tekshiring.",
            "O'chirish",
            "Bekor qilish");
        if (!confirmed)
            return;

        var finalConfirmation = await DisplayPromptAsync(
            "Tasdiqlash",
            "Tasdiqlash uchun O'CHIRISH so'zini kiriting.",
            "Davom etish",
            "Bekor qilish",
            maxLength: 12);
        if (!string.Equals(finalConfirmation, "O'CHIRISH", StringComparison.Ordinal))
            return;

        try
        {
            await _databaseService.DeleteAllDataAsync();
            await DisplayAlertAsync("Tayyor", "Barcha yozuvlar o'chirildi.", "OK");
            await RefreshDatabaseInfoAsync();
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(ex);
            await DisplayAlertAsync("Xatolik", "Ma'lumotlarni o'chirib bo'lmadi.", "OK");
        }
    }

    private async Task RefreshDatabaseInfoAsync()
    {
        try
        {
            var counts = await _databaseService.GetRecordCountsAsync();
            var size = await _databaseService.GetDatabaseSizeBytesAsync();
            DatabaseInfoLabel.Text =
                $"Saqlanganlar: {counts.HorseCount} ta ot, " +
                $"{counts.ProcessingCount} ta qayta ishlash, " +
                $"{counts.QaziCompositionCount} ta qazi tarkibi, " +
                $"{counts.ExpenseCount} ta xarajat, {counts.ProductCount} ta mahsulot. " +
                $"Baza hajmi: {size / 1024.0:N1} KB.";
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(ex);
            DatabaseInfoLabel.Text = "Ma'lumotlar bazasi holatini yuklab bo'lmadi.";
        }
    }
}
