namespace QaziCalculator.Services;

public static class AppThemeService
{
    private const string ThemePreferenceKey = "appearance_mode";

    public static event EventHandler? ThemeChanged;

    public static string CurrentMode =>
        Preferences.Default.Get(ThemePreferenceKey, "System");

    public static void ApplySavedTheme(Application application)
    {
        application.UserAppTheme = GetAppTheme(CurrentMode);
    }

    public static void SetTheme(Application application, string mode)
    {
        if (mode is not ("Light" or "Dark" or "System"))
            throw new ArgumentOutOfRangeException(nameof(mode));

        Preferences.Default.Set(ThemePreferenceKey, mode);
        application.UserAppTheme = GetAppTheme(mode);
        ThemeChanged?.Invoke(null, EventArgs.Empty);
    }

    public static void ToggleLightDark(Application application)
    {
        var isDark = CurrentMode switch
        {
            "Dark" => true,
            "Light" => false,
            _ => application.RequestedTheme == AppTheme.Dark
        };

        SetTheme(application, isDark ? "Light" : "Dark");
    }

    private static AppTheme GetAppTheme(string mode)
    {
        return mode switch
        {
            "Light" => AppTheme.Light,
            "Dark" => AppTheme.Dark,
            _ => AppTheme.Unspecified
        };
    }
}
