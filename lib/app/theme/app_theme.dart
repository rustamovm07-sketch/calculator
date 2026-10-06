import 'package:flutter/material.dart';

import 'design_tokens.dart';

class AppTheme {
  static const seed = Color(0xFF8B1E2D);

  static ThemeData light({
    Color accent = seed,
    AppUiStyle style = AppUiStyle.classic,
    GlassSettings glass = const GlassSettings(),
  }) =>
      _build(Brightness.light, accent, style, glass);

  static ThemeData dark({
    Color accent = seed,
    AppUiStyle style = AppUiStyle.classic,
    GlassSettings glass = const GlassSettings(),
  }) =>
      _build(Brightness.dark, accent, style, glass);

  static ThemeData _build(
    Brightness brightness,
    Color accent,
    AppUiStyle style,
    GlassSettings glass,
  ) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: brightness,
    );
    final cardColor = dark ? const Color(0xFF1B1B1F) : Colors.white;
    final cardAlpha = style.usesGlass
        ? (glass.surfaceOpacity * (1 - glass.transparency * .5))
            .clamp(.4, 1.0)
            .toDouble()
        : 1.0;
    final shadowAlpha =
        style.usesDepth ? (style.usesGlass ? glass.shadowIntensity : .18) : .04;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          dark ? const Color(0xFF111318) : const Color(0xFFF6F5F3),
      cardTheme: CardThemeData(
        elevation:
            style.usesDepth ? (style.usesGlass ? 1 + glass.depth * 5 : 3) : 0,
        shadowColor: Colors.black.withValues(alpha: shadowAlpha),
        color: cardColor.withValues(alpha: cardAlpha),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          side: style.usesGlass
              ? BorderSide(
                  color: (dark ? Colors.white : accent).withValues(
                    alpha: (glass.borderIntensity * .22 +
                            glass.highlightIntensity * .08)
                        .clamp(0, .3)
                        .toDouble(),
                  ),
                )
              : BorderSide.none,
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF25272D) : const Color(0xFFF0EEEC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.controlRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.controlRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.controlRadius),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          elevation: style.usesDepth ? 3 : 0,
          shadowColor: scheme.primary.withValues(alpha: .25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.controlRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.controlRadius),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extensions: [
        DesignTokens(style: style, glass: glass, accent: accent),
      ],
    );
  }
}
