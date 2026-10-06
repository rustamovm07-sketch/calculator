using Microsoft.Extensions.DependencyInjection;
using QaziCalculator.Services;

namespace QaziCalculator;

public partial class App : Application
{
	public App()
	{
		InitializeComponent();
		AppThemeService.ApplySavedTheme(this);
	}

	protected override Window CreateWindow(IActivationState? activationState)
	{
		return new Window(new AppShell());
	}
}