using QaziCalculator.Services;

namespace QaziCalculator.Views;

public partial class PageNavigationBar : ContentView
{
    private bool _isSubscribed;
    private Application? _observedApplication;

    public PageNavigationBar()
    {
        InitializeComponent();
        UpdateThemeButton();
    }

    protected override void OnParentSet()
    {
        base.OnParentSet();

        if (Parent is not null && !_isSubscribed)
        {
            AppThemeService.ThemeChanged += OnThemeChanged;
            _observedApplication = Application.Current;
            if (_observedApplication is not null)
                _observedApplication.RequestedThemeChanged += OnRequestedThemeChanged;
            _isSubscribed = true;
        }
        else if (Parent is null && _isSubscribed)
        {
            AppThemeService.ThemeChanged -= OnThemeChanged;
            if (_observedApplication is not null)
                _observedApplication.RequestedThemeChanged -= OnRequestedThemeChanged;
            _observedApplication = null;
            _isSubscribed = false;
        }

        UpdateThemeButton();
    }

    private async void HomeButton_Clicked(object? sender, EventArgs e)
    {
        await Shell.Current.GoToAsync("//DashboardPage");
    }

    private void ThemeToggleButton_Clicked(object? sender, EventArgs e)
    {
        if (Application.Current is null)
            return;

        AppThemeService.ToggleLightDark(Application.Current);
    }

    private void OnThemeChanged(object? sender, EventArgs e)
    {
        UpdateThemeButton();
    }

    private void OnRequestedThemeChanged(object? sender, AppThemeChangedEventArgs e)
    {
        UpdateThemeButton();
    }

    private void UpdateThemeButton()
    {
        var isDark = AppThemeService.CurrentMode switch
        {
            "Dark" => true,
            "Light" => false,
            _ => Application.Current?.RequestedTheme == AppTheme.Dark
        };

        ThemeToggleButton.Text = isDark ? "Yorug' rejim" : "Tungi rejim";
    }
}
