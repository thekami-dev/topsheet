import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_themes.dart';
import '../core/motion.dart';
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
                    child: Text('COLOR THEME', style: textTheme.labelSmall),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _ThemeGrid(entries: entries, current: current),
                  ),
                  if (dyn != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: Text(
                        'Dynamic uses the colours of your wallpaper.',
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

/// Responsive grid of compact swatches (3 columns on a typical phone).
class _ThemeGrid extends StatelessWidget {
  static const _gap = 10.0;
  static const _minTileW = 96.0;
  static const _tileH = 80.0;

  final List<_Entry> entries;
  final String current;

  const _ThemeGrid({required this.entries, required this.current});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final cols = ((box.maxWidth + _gap) / (_minTileW + _gap))
            .floor()
            .clamp(2, 6)
            .toInt();
        final tileW = (box.maxWidth - _gap * (cols - 1)) / cols;
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final e in entries)
              SizedBox(
                width: tileW,
                height: _tileH,
                child: _ThemeSwatch(
                  entry: e,
                  selected: e.id == current,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    applyThemePalette(e.id);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One compact swatch: the palette's own background, a pill with its key
/// colours, and its name. Selected = accent ring + small check.
class _ThemeSwatch extends StatelessWidget {
  final _Entry entry;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeSwatch({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = entry.colors;
    final textTheme = Theme.of(context).textTheme;
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final dur = reduced ? Duration.zero : Motion.standard;

    Widget dot(Color color) => Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: entry.name,
      excludeSemantics: true,
      onTap: onTap,
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.97,
        child: AnimatedContainer(
          duration: dur,
          curve: Motion.standardCurve,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? c.accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.bg,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: c.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: c.surface2,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            dot(c.accent),
                            const SizedBox(width: 4),
                            dot(c.accent2),
                            const SizedBox(width: 4),
                            dot(c.success),
                          ],
                        ),
                      ),
                      const Spacer(),
                      AnimatedScale(
                        scale: selected ? 1 : 0.6,
                        duration: dur,
                        curve: Motion.standardCurve,
                        child: AnimatedOpacity(
                          opacity: selected ? 1 : 0,
                          duration: dur,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: c.accent,
                              shape: BoxShape.circle,
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
                  Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: c.text,
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
