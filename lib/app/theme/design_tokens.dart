import 'package:flutter/material.dart';

enum AppUiStyle {
  classic('Classic', 'Klassik'),
  threeD('3D', 'Hajmli'),
  liquidGlass('Liquid Glass', 'Shisha'),
  threeDLiquidGlass('3D Liquid Glass', 'Hajmli shisha');

  const AppUiStyle(this.storageKey, this.label);

  final String storageKey;
  final String label;

  bool get usesGlass =>
      this == AppUiStyle.liquidGlass || this == AppUiStyle.threeDLiquidGlass;

  bool get usesDepth =>
      this == AppUiStyle.threeD || this == AppUiStyle.threeDLiquidGlass;

  static AppUiStyle fromStorage(String? value) => AppUiStyle.values.firstWhere(
        (style) => style.storageKey == value,
        orElse: () => AppUiStyle.classic,
      );
}

@immutable
class GlassSettings {
  const GlassSettings({
    this.transparency = .24,
    this.blur = 8,
    this.intensity = .62,
    this.surfaceOpacity = .84,
    this.borderIntensity = .42,
    this.shadowIntensity = .3,
    this.highlightIntensity = .35,
    this.depth = .35,
  });

  final double transparency;
  final double blur;
  final double intensity;
  final double surfaceOpacity;
  final double borderIntensity;
  final double shadowIntensity;
  final double highlightIntensity;
  final double depth;

  GlassSettings copyWith({
    double? transparency,
    double? blur,
    double? intensity,
    double? surfaceOpacity,
    double? borderIntensity,
    double? shadowIntensity,
    double? highlightIntensity,
    double? depth,
  }) =>
      GlassSettings(
        transparency: transparency ?? this.transparency,
        blur: blur ?? this.blur,
        intensity: intensity ?? this.intensity,
        surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
        borderIntensity: borderIntensity ?? this.borderIntensity,
        shadowIntensity: shadowIntensity ?? this.shadowIntensity,
        highlightIntensity: highlightIntensity ?? this.highlightIntensity,
        depth: depth ?? this.depth,
      );

  Map<String, double> toMap() => {
        'transparency': transparency,
        'blur': blur,
        'intensity': intensity,
        'surfaceOpacity': surfaceOpacity,
        'borderIntensity': borderIntensity,
        'shadowIntensity': shadowIntensity,
        'highlightIntensity': highlightIntensity,
        'depth': depth,
      };

  factory GlassSettings.fromMap(Map<String, dynamic>? map) {
    double value(String key, double fallback) {
      final raw = map?[key];
      if (raw is num && raw.isFinite) return raw.toDouble().clamp(0, 1);
      return fallback;
    }

    return GlassSettings(
      transparency: value('transparency', .24),
      blur: map?['blur'] is num
          ? (map!['blur'] as num).toDouble().clamp(0, 10)
          : 8,
      intensity: value('intensity', .62),
      surfaceOpacity: value('surfaceOpacity', .84),
      borderIntensity: value('borderIntensity', .42),
      shadowIntensity: value('shadowIntensity', .3),
      highlightIntensity: value('highlightIntensity', .35),
      depth: value('depth', .35),
    );
  }
}

@immutable
class DesignTokens extends ThemeExtension<DesignTokens> {
  static const space1 = 4.0;
  static const space2 = 8.0;
  static const space3 = 12.0;
  static const space4 = 16.0;
  static const space5 = 20.0;
  static const cardRadius = 22.0;
  static const controlRadius = 16.0;
  static const tileRadius = 18.0;
  static const animationFast = Duration(milliseconds: 180);
  static const animationNormal = Duration(milliseconds: 320);

  const DesignTokens({
    required this.style,
    required this.glass,
    required this.accent,
  });

  final AppUiStyle style;
  final GlassSettings glass;
  final Color accent;

  static DesignTokens of(BuildContext context) =>
      Theme.of(context).extension<DesignTokens>() ??
      const DesignTokens(
        style: AppUiStyle.classic,
        glass: GlassSettings(),
        accent: Color(0xFF8B1E2D),
      );

  @override
  DesignTokens copyWith({
    AppUiStyle? style,
    GlassSettings? glass,
    Color? accent,
  }) =>
      DesignTokens(
        style: style ?? this.style,
        glass: glass ?? this.glass,
        accent: accent ?? this.accent,
      );

  @override
  DesignTokens lerp(ThemeExtension<DesignTokens>? other, double t) {
    if (other is! DesignTokens) return this;
    return DesignTokens(
      style: t < .5 ? style : other.style,
      glass: t < .5 ? glass : other.glass,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
    );
  }
}
