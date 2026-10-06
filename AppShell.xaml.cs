using QaziCalculator.Views;

namespace QaziCalculator;

public partial class AppShell : Shell
{
	public AppShell()
	{
		InitializeComponent();
		Routing.RegisterRoute(nameof(HorseDetailsPage), typeof(HorseDetailsPage));
		Routing.RegisterRoute(nameof(QaziCompositionPage), typeof(QaziCompositionPage));
		Routing.RegisterRoute(nameof(ExpensesPage), typeof(ExpensesPage));
		Routing.RegisterRoute(nameof(ProductsPage), typeof(ProductsPage));
		Routing.RegisterRoute(nameof(ReportsPage), typeof(ReportsPage));
		Routing.RegisterRoute(nameof(SettingsPage), typeof(SettingsPage));
	}
}
