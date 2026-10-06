import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/database_service.dart';
import 'theme/design_tokens.dart';
import '../models/expense.dart';
import '../models/horse_batch.dart';
import '../models/processing_result.dart';
import '../models/product.dart';
import '../models/qazi_composition.dart';
import 'theme/app_theme.dart';

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
  bool hasInitialized = false;
  ThemeMode themeMode = ThemeMode.system;
  AppUiStyle uiStyle = AppUiStyle.classic;
  Color accentColor = AppTheme.seed;
  GlassSettings glassSettings = const GlassSettings();
  int calculatorPrecision = 8;
  bool hapticFeedback = true;
  List<Map<String, Object?>> calculatorHistory = [];

  Future<void> initialize() async {
    themeMode = switch (preferences.getString('appearance_mode')) {
      'Light' => ThemeMode.light,
      'Dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    uiStyle = AppUiStyle.fromStorage(preferences.getString('ui_style'));
    final storedAccent = preferences.getInt('accent_color');
    if (storedAccent != null &&
        Color(storedAccent).computeLuminance().isFinite) {
      accentColor = Color(storedAccent);
    }
    final storedGlass = preferences.getString('glass_settings');
    if (storedGlass != null) {
      try {
        final decoded = jsonDecode(storedGlass);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Glass settings must be a JSON object.');
        }
        glassSettings = GlassSettings.fromMap(decoded);
      } on FormatException catch (error) {
        debugPrint('Ignoring invalid saved glass settings: $error');
        await preferences.remove('glass_settings');
      }
    }
    calculatorPrecision =
        (preferences.getInt('calculator_precision') ?? 8).clamp(0, 12);
    hapticFeedback = preferences.getBool('calculator_haptics') ?? true;
    final storedHistory = preferences.getString('calculator_history');
    if (storedHistory != null) {
      try {
        final decoded = jsonDecode(storedHistory);
        if (decoded is! List ||
            decoded.any(
              (entry) =>
                  entry is! Map ||
                  entry['expression'] is! String ||
                  entry['result'] is! String,
            )) {
          throw const FormatException('Saved calculator history is invalid.');
        }
        calculatorHistory = decoded
            .cast<Map>()
            .map((entry) => Map<String, Object?>.from(entry))
            .take(50)
            .toList();
      } on FormatException catch (error) {
        debugPrint('Ignoring invalid saved calculator history: $error');
        await preferences.remove('calculator_history');
      }
    }
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

  Future<void> setUiStyle(AppUiStyle style) async {
    uiStyle = style;
    await preferences.setString('ui_style', style.storageKey);
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    accentColor = color;
    await preferences.setInt('accent_color', color.toARGB32());
    notifyListeners();
  }

  Future<void> setGlassSettings(GlassSettings settings) async {
    glassSettings = settings;
    await preferences.setString('glass_settings', jsonEncode(settings.toMap()));
    notifyListeners();
  }

  Future<void> setCalculatorPrecision(int precision) async {
    calculatorPrecision = precision.clamp(0, 12);
    await preferences.setInt('calculator_precision', calculatorPrecision);
    notifyListeners();
  }

  Future<void> setHapticFeedback(bool enabled) async {
    hapticFeedback = enabled;
    await preferences.setBool('calculator_haptics', enabled);
    notifyListeners();
  }

  Future<void> addCalculatorHistory(String expression, String result) async {
    calculatorHistory = [
      {
        'expression': expression,
        'result': result,
        'createdAt': DateTime.now().toIso8601String(),
      },
      ...calculatorHistory,
    ].take(50).toList();
    await preferences.setString(
      'calculator_history',
      jsonEncode(calculatorHistory),
    );
    notifyListeners();
  }

  Future<void> clearCalculatorHistory() async {
    calculatorHistory = [];
    await preferences.setString('calculator_history', '[]');
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
      hasInitialized = true;
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
