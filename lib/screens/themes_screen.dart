import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../core/app_themes.dart';
import '../core/motion.dart';
import '../core/theme_reveal.dart';
import '../main.dart' show themeModeNotifier, applyThemeMode;
import '../widgets/pressable.dart';

class _Entry {
  final String id;
  final String name;
  final PaletteColors colors;
  const _Entry(this.id, this.name, this.colors);
}

void _setMode(ThemeMode m) {
  HapticFeedback.selectionClick();
  applyThemeMode(switch (m) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  });
}

class ThemesScreen extends StatelessWidget {
  const ThemesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Themes')),
      body: DynamicColorBuilder(
        builder: (lightDyn, darkDyn) {
          final dyn = isDark ? darkDyn : lightDyn;
          return ListenableBuilder(
            listenable: Listenable.merge([
              themePaletteNotifier,
              themePureBlackNotifier,
            ]),
            builder: (context, _) {
              final current = themePaletteNotifier.value;
              final black = themePureBlackNotifier.value;
              PaletteColors tone(PaletteColors c) =>
                  isDark && black ? pureBlackOf(c) : c;
              final entries = <_Entry>[
                for (final p in kPalettes)
                  _Entry(p.id, p.name, tone(isDark ? p.dark : p.light)),
              ];
              if (dyn != null) {
                entries.insert(
                  1,
                  _Entry(
                    dynamicPaletteId,
                    'Dynamic',
                    tone(paletteFromScheme(dyn)),
                  ),
                );
              }
              final currentName = entries
                  .firstWhere(
                    (e) => e.id == current,
                    orElse: () => entries.first,
                  )
                  .name;
              return ListView(
                padding: EdgeInsets.only(top: 8, bottom: 32 + bottomInset),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                    child: Text('APPEARANCE', style: textTheme.labelSmall),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ValueListenableBuilder<ThemeMode>(
                      valueListenable: themeModeNotifier,
                      builder: (context, mode, _) {
                        return SegmentedButton<ThemeMode>(
                          showSelectedIcon: true,
                          segments: const [
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text('System'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text('Light'),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text('Dark'),
                            ),
                          ],
                          selected: {mode},
                          onSelectionChanged: (s) => _setMode(s.first),
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.resolveWith<Color?>(
                                  (st) => st.contains(WidgetState.selected)
                                      ? scheme.primary.withValues(alpha: 0.18)
                                      : Colors.transparent,
                                ),
                            foregroundColor:
                                WidgetStateProperty.resolveWith<Color?>(
                                  (st) => st.contains(WidgetState.selected)
                                      ? scheme.secondary
                                      : scheme.onSurfaceVariant,
                                ),
                            side: WidgetStatePropertyAll(
                              BorderSide(color: scheme.outlineVariant),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pure black dark mode',
                                style: textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'True black background in dark mode. '
                                'Saves battery on AMOLED screens.',
                                style: textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: black,
                          onChanged: (v) {
                            HapticFeedback.selectionClick();
                            applyThemePureBlack(v);
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                    child: Row(
                      children: [
                        Text('COLOR THEME', style: textTheme.labelSmall),
                        const Spacer(),
                        Text(
                          currentName,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _ThemeGrid(entries: entries, current: current),
                  ),
                  if (dyn != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Text(
                        'Dynamic uses the colours of your wallpaper. '
                        'Long-press a circle to see its name.',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Grid of round swatches, evenly spaced; columns adapt to the width.
class _ThemeGrid extends StatelessWidget {
  static const _minCellW = 72.0;

  final List<_Entry> entries;
  final String current;

  const _ThemeGrid({required this.entries, required this.current});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final cols = (box.maxWidth / _minCellW).floor().clamp(3, 8).toInt();
        final cellW = (box.maxWidth / cols).floorToDouble();
        return Wrap(
          runSpacing: 10,
          children: [
            for (final e in entries)
              SizedBox(
                width: cellW,
                height: _ThemeSwatch.size,
                child: Center(
                  child: _ThemeSwatch(
                    entry: e,
                    selected: e.id == current,
                    onTap: (origin) {
                      if (e.id == current) return;
                      HapticFeedback.selectionClick();
                      ThemeReveal.instance.run(origin, () {
                        applyThemePalette(e.id);
                      });
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One round swatch: the palette's background as the disc, its two accent
/// colours as the core. Selected = accent ring + small check badge.
class _ThemeSwatch extends StatelessWidget {
  static const size = 60.0;

  final _Entry entry;
  final bool selected;
  final void Function(Offset origin) onTap;

  const _ThemeSwatch({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = entry.colors;
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final dur = reduced ? Duration.zero : Motion.standard;

    void tap() {
      final box = context.findRenderObject() as RenderBox;
      onTap(box.localToGlobal(box.size.center(Offset.zero)));
    }

    return Semantics(
      button: true,
      selected: selected,
      label: entry.name,
      excludeSemantics: true,
      onTap: tap,
      child: Tooltip(
        message: entry.name,
        child: Pressable(
          onTap: tap,
          pressedScale: 0.92,
          child: Stack(
            children: [
              AnimatedContainer(
                duration: dur,
                curve: Motion.standardCurve,
                width: size,
                height: size,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? c.accent : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.bg,
                    border: Border.all(color: c.border),
                  ),
                  child: Center(
                    child: ClipOval(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: Row(
                          children: [
                            Expanded(child: ColoredBox(color: c.accent)),
                            Expanded(child: ColoredBox(color: c.accent2)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: dur,
                  curve: Motion.standardCurve,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: c.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.bg, width: 2),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: c.onAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
