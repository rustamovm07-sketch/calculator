import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final state = AppState(preferences);
  runApp(AdenalinCalculatorApp(state: state));
  unawaited(state.initialize());
}
