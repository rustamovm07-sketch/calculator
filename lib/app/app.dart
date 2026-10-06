import 'package:flutter/material.dart';

import '../features/analytics/statistics_page.dart';
import '../features/calculator/presentation/calculator_page.dart';
import '../features/horses/presentation/dashboard_page.dart';
import '../features/horses/presentation/history_page.dart';
import '../features/settings/presentation/more_page.dart';
import 'app_state.dart';
import 'theme/app_theme.dart';

class AdenalinCalculatorApp extends StatelessWidget {
  const AdenalinCalculatorApp({required this.state, super.key});

  final AppState state;

  @override
  Widget build(BuildContext context) => AppScope(
        state: state,
        child: AnimatedBuilder(
          animation: state,
          builder: (context, _) => MaterialApp(
            title: 'Adenalin Calculator',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(
              accent: state.accentColor,
              style: state.uiStyle,
              glass: state.glassSettings,
            ),
            darkTheme: AppTheme.dark(
              accent: state.accentColor,
              style: state.uiStyle,
              glass: state.glassSettings,
            ),
            themeMode: state.themeMode,
            home: const AppHome(),
          ),
        ),
      );
}

class AppHome extends StatefulWidget {
  const AppHome({super.key});

  @override
  State<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  var _selectedIndex = 0;
  static const _pages = <Widget>[
    DashboardPage(),
    CalculatorPage(),
    HistoryPage(),
    StatisticsPage(),
    MorePage(),
  ];
  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Uy',
    ),
    NavigationDestination(
      icon: Icon(Icons.calculate_outlined),
      selectedIcon: Icon(Icons.calculate),
      label: 'Hisob',
    ),
    NavigationDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history),
      label: 'Tarix',
    ),
    NavigationDestination(
      icon: Icon(Icons.insights_outlined),
      selectedIcon: Icon(Icons.insights),
      label: 'Tahlil',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu_rounded),
      selectedIcon: Icon(Icons.menu_open),
      label: 'Ko‘proq',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (state.loadError != null) {
      return MaterialApp(
        theme: AppTheme.light(
          accent: state.accentColor,
          style: state.uiStyle,
          glass: state.glassSettings,
        ),
        darkTheme: AppTheme.dark(
          accent: state.accentColor,
          style: state.uiStyle,
          glass: state.glassSettings,
        ),
        themeMode: state.themeMode,
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storage_rounded, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Ma’lumotlarni ochib bo‘lmadi',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('${state.loadError}', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: state.reload,
                      child: const Text('Qayta urinish'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: state.isLoading && !state.hasInitialized
          ? const _BrandedSplash(key: ValueKey('startup-splash'))
          : LayoutBuilder(
              key: const ValueKey('application-home'),
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                return Scaffold(
                  body: SafeArea(
                    child: Row(
                      children: [
                        if (wide)
                          NavigationRail(
                            selectedIndex: _selectedIndex,
                            onDestinationSelected: (index) =>
                                setState(() => _selectedIndex = index),
                            labelType: NavigationRailLabelType.all,
                            destinations: _destinations
                                .map(
                                  (item) => NavigationRailDestination(
                                    icon: item.icon,
                                    selectedIcon: item.selectedIcon,
                                    label: Text(item.label),
                                  ),
                                )
                                .toList(),
                          ),
                        Expanded(
                          child: IndexedStack(
                              index: _selectedIndex, children: _pages),
                        ),
                      ],
                    ),
                  ),
                  bottomNavigationBar: wide
                      ? null
                      : NavigationBar(
                          labelBehavior: NavigationDestinationLabelBehavior
                              .onlyShowSelected,
                          selectedIndex: _selectedIndex,
                          onDestinationSelected: (index) =>
                              setState(() => _selectedIndex = index),
                          destinations: _destinations,
                        ),
                );
              },
            ),
    );
  }
}

class _BrandedSplash extends StatefulWidget {
  const _BrandedSplash({super.key});

  @override
  State<_BrandedSplash> createState() => _BrandedSplashState();
}

class _BrandedSplashState extends State<_BrandedSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..forward();
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  late final Animation<double> _scale = Tween<double>(begin: .92, end: 1)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/images/adenalin_icon.png',
                        width: 104,
                        height: 104,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Adenalin Calculator',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hisob-kitob va ishlab chiqarish tahlili',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
