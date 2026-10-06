import 'dart:convert';

import 'package:adenalin_calculator/app/app_state.dart';
import 'package:adenalin_calculator/app/theme/app_theme.dart';
import 'package:adenalin_calculator/app/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('persists independent theme, palette, style, and glass choices',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final state = AppState(preferences);
    const accent = Color(0xFF18845B);
    const glass = GlassSettings(
      transparency: .42,
      blur: 7,
      intensity: .8,
      surfaceOpacity: .7,
      borderIntensity: .6,
      shadowIntensity: .25,
      highlightIntensity: .9,
      depth: .5,
    );

    await state.setTheme(ThemeMode.dark);
    await state.setAccentColor(accent);
    await state.setUiStyle(AppUiStyle.threeDLiquidGlass);
    await state.setGlassSettings(glass);

    expect(preferences.getString('appearance_mode'), 'Dark');
    expect(preferences.getInt('accent_color'), accent.toARGB32());
    expect(preferences.getString('ui_style'), '3D Liquid Glass');
    expect(
      GlassSettings.fromMap(
        Map<String, dynamic>.from(
          (jsonDecode(preferences.getString('glass_settings')!) as Map),
        ),
      ).toMap(),
      glass.toMap(),
    );
  });

  test('clamps restored glass values to safe bounds', () {
    final settings = GlassSettings.fromMap({
      'transparency': 3,
      'blur': 80,
      'intensity': -1,
      'surfaceOpacity': .75,
    });
    expect(settings.transparency, 1);
    expect(settings.blur, 10);
    expect(settings.intensity, 0);
    expect(settings.surfaceOpacity, .75);
  });

  test('builds coordinated themes for all styles and both brightness modes',
      () {
    for (final style in AppUiStyle.values) {
      for (final brightness in Brightness.values) {
        final theme = brightness == Brightness.light
            ? AppTheme.light(style: style)
            : AppTheme.dark(style: style);
        expect(theme.useMaterial3, isTrue);
        expect(theme.colorScheme.brightness, brightness);
        expect(theme.extension<DesignTokens>()?.style, style);
      }
    }
  });
}
