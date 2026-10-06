import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../app/app_state.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../widgets/app_components.dart';

class AppearanceSettingsSection extends StatefulWidget {
  const AppearanceSettingsSection({super.key});

  @override
  State<AppearanceSettingsSection> createState() =>
      _AppearanceSettingsSectionState();
}

class _AppearanceSettingsSectionState extends State<AppearanceSettingsSection> {
  static const _palettes = <(String, Color)>[
    ('Rose', Color(0xFFC44569)),
    ('Burgundy', Color(0xFF722F37)),
    ('Crimson', Color(0xFFB3263E)),
    ('Violet', Color(0xFF7653C1)),
    ('Blue', Color(0xFF3568C0)),
    ('Cyan', Color(0xFF008C9E)),
    ('Emerald', Color(0xFF18845B)),
    ('Amber', Color(0xFFAA6900)),
    ('Monochrome', Color(0xFF555B66)),
  ];

  late GlassSettings _glass = AppScope.of(context).glassSettings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _glass = AppScope.of(context).glassSettings;
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final tokens = DesignTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionCard(
          title: 'Ranglar palitrasi',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Urg‘u rangi barcha asosiy tugma va tanlovlarda ishlatiladi.'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (name, color) in _palettes)
                    ChoiceChip(
                      avatar: CircleAvatar(backgroundColor: color, radius: 8),
                      label: Text(name),
                      selected:
                          state.accentColor.toARGB32() == color.toARGB32(),
                      onSelected: (_) => state.setAccentColor(color),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => _chooseCustomColor(state.accentColor),
                    icon:
                        Icon(Icons.palette_outlined, color: state.accentColor),
                    label: const Text('Maxsus rang'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _AccentPreview(color: state.accentColor),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Interfeys uslubi',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Barcha ekranlar uchun bir xil dizayn uslubini tanlang.'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final style in AppUiStyle.values)
                    ChoiceChip(
                      avatar: Icon(
                        _styleIcon(style),
                        size: 18,
                        color: state.uiStyle == style
                            ? scheme.onSecondaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                      label: Text(style.label),
                      selected: state.uiStyle == style,
                      onSelected: (_) => state.setUiStyle(style),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (tokens.style.usesGlass) ...[
          const SizedBox(height: 12),
          SectionCard(
            title: 'Liquid Glass sozlamalari',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Slayderlarni o‘zgartirganda ko‘rinish jonli yangilanadi. '
                  'Xiralashtirish 10 px bilan cheklangan.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                _GlassPreview(settings: _glass, accent: state.accentColor),
                const SizedBox(height: 12),
                _slider(
                  title: 'Shaffoflik',
                  value: _glass.transparency,
                  onChanged: (value) => _updateGlass(
                    _glass.copyWith(transparency: value),
                  ),
                  onChangeEnd: (_) => _saveGlass(state),
                ),
                _slider(
                  title: 'Xiralashtirish',
                  value: _glass.blur / 10,
                  valueText: '${_glass.blur.toStringAsFixed(0)} px',
                  onChanged: (value) => _updateGlass(
                    _glass.copyWith(blur: value * 10),
                  ),
                  onChangeEnd: (_) => _saveGlass(state),
                ),
                _slider(
                  title: 'Shisha intensivligi',
                  value: _glass.intensity,
                  onChanged: (value) => _updateGlass(
                    _glass.copyWith(intensity: value),
                  ),
                  onChangeEnd: (_) => _saveGlass(state),
                ),
                _slider(
                  title: 'Sirt xiraligi',
                  value: _glass.surfaceOpacity,
                  onChanged: (value) => _updateGlass(
                    _glass.copyWith(surfaceOpacity: value),
                  ),
                  onChangeEnd: (_) => _saveGlass(state),
                ),
                _slider(
                  title: 'Chegara yorqinligi',
                  value: _glass.borderIntensity,
                  onChanged: (value) => _updateGlass(
                    _glass.copyWith(borderIntensity: value),
                  ),
                  onChangeEnd: (_) => _saveGlass(state),
                ),
                _slider(
                  title: 'Soya kuchi',
                  value: _glass.shadowIntensity,
                  onChanged: (value) => _updateGlass(
                    _glass.copyWith(shadowIntensity: value),
                  ),
                  onChangeEnd: (_) => _saveGlass(state),
                ),
                _slider(
                  title: 'Yorug‘lik aksenti',
                  value: _glass.highlightIntensity,
                  onChanged: (value) => _updateGlass(
                    _glass.copyWith(highlightIntensity: value),
                  ),
                  onChangeEnd: (_) => _saveGlass(state),
                ),
                _slider(
                  title: 'Chuqurlik',
                  value: _glass.depth,
                  onChanged: (value) =>
                      _updateGlass(_glass.copyWith(depth: value)),
                  onChangeEnd: (_) => _saveGlass(state),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  IconData _styleIcon(AppUiStyle style) => switch (style) {
        AppUiStyle.classic => Icons.dashboard_outlined,
        AppUiStyle.threeD => Icons.view_in_ar_outlined,
        AppUiStyle.liquidGlass => Icons.blur_on_outlined,
        AppUiStyle.threeDLiquidGlass => Icons.layers_outlined,
      };

  Widget _slider({
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
    String? valueText,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title)),
              Text(
                valueText ?? '${(value * 100).round()}%',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(0, 1).toDouble(),
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ],
      );

  void _updateGlass(GlassSettings value) {
    setState(() => _glass = value);
  }

  Future<void> _saveGlass(AppState state) => state.setGlassSettings(_glass);

  Future<void> _chooseCustomColor(Color initial) async {
    final color = await showDialog<Color>(
      context: context,
      builder: (context) => _CustomColorDialog(initial: initial),
    );
    if (color != null && mounted) {
      await AppScope.of(context).setAccentColor(color);
    }
  }
}

class _AccentPreview extends StatelessWidget {
  const _AccentPreview({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final foreground =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .3)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: foreground,
            ),
            onPressed: () {},
            child: const Text('Jonli namuna'),
          ),
          Icon(Icons.check_circle, color: color),
          Text('Faol tanlov', style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

class _GlassPreview extends StatelessWidget {
  const _GlassPreview({required this.settings, required this.accent});

  final GlassSettings settings;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final sigma = (settings.blur * settings.intensity).clamp(0, 10).toDouble();
    final preview = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(
              alpha:
                  (settings.surfaceOpacity * (1 - settings.transparency * .5))
                      .clamp(.4, 1.0)
                      .toDouble(),
            ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: settings.borderIntensity),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: settings.shadowIntensity * .18),
            blurRadius: 16 * settings.depth,
            offset: Offset(0, 3 * settings.depth),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 48,
              height: 3,
              decoration: BoxDecoration(
                color:
                    Colors.white.withValues(alpha: settings.highlightIntensity),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.water_drop_outlined, color: accent),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Namuna sirt',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${(settings.intensity * 100).round()}%',
                style: TextStyle(color: accent, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
    if (sigma == 0) return preview;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: preview,
      ),
    );
  }
}

class _CustomColorDialog extends StatefulWidget {
  const _CustomColorDialog({required this.initial});
  final Color initial;

  @override
  State<_CustomColorDialog> createState() => _CustomColorDialogState();
}

class _CustomColorDialogState extends State<_CustomColorDialog> {
  late HSVColor _color = HSVColor.fromColor(widget.initial);

  @override
  Widget build(BuildContext context) {
    final color = _color.toColor();
    return AlertDialog(
      title: const Text('Maxsus urg‘u rangi'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 12),
            _colorSlider('Tus', _color.hue, 360, (v) {
              setState(() => _color = _color.withHue(v));
            }, rainbow: true),
            _colorSlider('To‘yinganlik', _color.saturation, 1, (v) {
              setState(() => _color = _color.withSaturation(v));
            }),
            _colorSlider('Yorqinlik', _color.value, 1, (v) {
              setState(() => _color = _color.withValue(v));
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, color),
          child: const Text('Tanlash'),
        ),
      ],
    );
  }

  Widget _colorSlider(
    String label,
    double value,
    double max,
    ValueChanged<double> onChanged, {
    bool rainbow = false,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          Slider(
            value: value.clamp(0, max).toDouble(),
            max: max,
            activeColor:
                rainbow ? HSVColor.fromAHSV(1, value, 1, 1).toColor() : null,
            onChanged: onChanged,
          ),
        ],
      );
}
