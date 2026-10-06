import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app/theme/design_tokens.dart';

class PageHeading extends StatelessWidget {
  const PageHeading(this.title, {this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      );
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.title,
    required this.child,
    this.trailing,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tokens.style.usesGlass) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 44,
                  height: 2,
                  decoration: BoxDecoration(
                    color: tokens.accent.withValues(
                      alpha: tokens.glass.highlightIntensity,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
    return card;
  }
}

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    required this.child,
    this.borderRadius = DesignTokens.cardRadius,
    super.key,
  });

  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    if (!tokens.style.usesGlass || tokens.glass.blur == 0) return child;
    final sigma =
        (tokens.glass.blur * tokens.glass.intensity).clamp(0, 10).toDouble();
    if (sigma == 0) return child;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.label,
    required this.value,
    this.icon,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: tokens.style.usesGlass ? tokens.glass.surfaceOpacity : .45,
        ),
        borderRadius: BorderRadius.circular(18),
        border: tokens.style.usesGlass
            ? Border.all(
                color: tokens.accent
                    .withValues(alpha: tokens.glass.borderIntensity * .3),
              )
            : null,
        boxShadow: tokens.style.usesDepth
            ? [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: tokens.style.usesGlass
                        ? tokens.glass.shadowIntensity * .12
                        : .1,
                  ),
                  blurRadius:
                      8 * (tokens.style.usesGlass ? tokens.glass.depth : 1),
                  offset: Offset(
                    0,
                    3 * (tokens.style.usesGlass ? tokens.glass.depth : 1),
                  ),
                ),
              ]
            : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 220 && icon != null;
          final labelText = Text(
            label,
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          );
          final valueText = Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (compact
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.titleLarge)
                ?.copyWith(fontWeight: FontWeight.w800),
          );
          if (compact) {
            return Row(
              children: [
                Icon(icon, size: 19, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [labelText, valueText],
                  ),
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) Icon(icon, size: 19, color: scheme.primary),
              if (icon != null) const SizedBox(height: 8),
              labelText,
              const SizedBox(height: 4),
              valueText,
            ],
          );
        },
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
        child: Column(
          children: [
            Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      );
}

String formatKg(num value, {int decimals = 2}) =>
    '${value.toStringAsFixed(decimals)} kg';
String formatMoney(num value) => '${value.toStringAsFixed(0)} so‘m';

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tasdiqlash'),
          ),
        ],
      ),
    ) ??
    false;

Future<void> pushPage(BuildContext context, Widget page) async {
  await Navigator.of(context)
      .push<void>(MaterialPageRoute<void>(builder: (context) => page));
}

Widget pageContent({
  required String title,
  required List<Widget> children,
  String? subtitle,
}) =>
    CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              PageHeading(title, subtitle: subtitle),
              const SizedBox(height: 20),
              ...children,
            ]),
          ),
        ),
      ],
    );
