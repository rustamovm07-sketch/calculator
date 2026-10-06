import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/database_service.dart';
import '../models/expense.dart';
import '../models/horse_batch.dart';
import '../models/processing_result.dart';
import '../models/product.dart';
import '../models/qazi_composition.dart';

class AppState extends ChangeNotifier {
  AppState(this.preferences);

  final SharedPreferences preferences;
  final DatabaseService database = DatabaseService.instance;
  List<HorseBatch> horses = [];
  List<ProcessingResult> results = [];
  List<QaziComposition> qaziCompositions = [];
  List<Expense> expenses = [];
  List<Product> products = [];
  Object? loadError;
  bool isLoading = true;
  ThemeMode themeMode = ThemeMode.system;

  Future<void> initialize() async {
    themeMode = switch (preferences.getString('appearance_mode')) {
      'Light' => ThemeMode.light,
      'Dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    await reload();
  }

  Future<void> setTheme(ThemeMode mode) async {
    themeMode = mode;
    final value = switch (mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
    };
    await preferences.setString('appearance_mode', value);
    notifyListeners();
  }

  Future<void> reload() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      final loaded = await Future.wait<Object>([
        database.getHorseBatches(),
        database.getProcessingResults(),
        database.getQaziCompositions(),
        database.getExpenses(),
        database.getProducts(),
      ]);
      horses = loaded[0] as List<HorseBatch>;
      results = loaded[1] as List<ProcessingResult>;
      qaziCompositions = loaded[2] as List<QaziComposition>;
      expenses = loaded[3] as List<Expense>;
      products = loaded[4] as List<Product>;
    } catch (error) {
      loadError = error;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({required AppState state, required super.child, super.key})
      : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    final state = scope?.notifier;
    if (state == null) throw StateError('AppScope is missing.');
    return state;
  }
}
