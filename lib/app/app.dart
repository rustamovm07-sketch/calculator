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
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
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
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
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
    return LayoutBuilder(
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
                  child: IndexedStack(index: _selectedIndex, children: _pages),
                ),
              ],
            ),
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  labelBehavior:
                      NavigationDestinationLabelBehavior.onlyShowSelected,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _selectedIndex = index),
                  destinations: _destinations,
                ),
        );
      },
    );
  }
}
