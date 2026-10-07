import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_themes.dart';
import '../main.dart' show themeModeNotifier, applyThemeMode;
import '../widgets/pressable.dart';

class _Entry {
  final String id;
  final String name;
  final PaletteColors colors;
  const _Entry(this.id, this.name, this.colors);
}

class _NoGlow extends ScrollBehavior {
  const _NoGlow();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

class ThemesScreen extends StatefulWidget {
  const ThemesScreen({super.key});

  @override
  State<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends State<ThemesScreen> {
  static const _cardW = 128.0;
  static const _gap = 14.0;
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    final idx = kPalettes.indexWhere((p) => p.id == themePaletteNotifier.value);
    _scroll = ScrollController(
      initialScrollOffset: idx <= 0 ? 0 : idx * (_cardW + _gap),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _setMode(ThemeMode m) {
    HapticFeedback.selectionClick();
    applyThemeMode(switch (m) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }

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
          return ValueListenableBuilder<String>(
            valueListenable: themePaletteNotifier,
            builder: (context, current, _) {
              final entries = <_Entry>[
                for (final p in kPalettes)
                  _Entry(p.id, p.name, isDark ? p.dark : p.light),
              ];
              if (dyn != null) {
                entries.insert(
                  1,
                  _Entry(dynamicPaletteId, 'Dynamic', paletteFromScheme(dyn)),
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
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                    child: Text('COLOR THEME', style: textTheme.labelSmall),
                  ),
                  SizedBox(
                    height: 250,
                    child: ScrollConfiguration(
                      behavior: const _NoGlow(),
                      child: ListView.separated(
                        controller: _scroll,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: _gap),
                        itemBuilder: (context, i) {
                          final e = entries[i];
                          return _ThemeCard(
                            entry: e,
                            selected: e.id == current,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              applyThemePalette(e.id);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  if (dyn != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
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

/// Mini phone mock-up that previews one palette.
class _ThemeCard extends StatelessWidget {
  final _Entry entry;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = entry.colors;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.97,
      child: SizedBox(
        width: 128,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 196,
              decoration: BoxDecoration(
                color: c.bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? c.accent : c.border,
                  width: selected ? 2.5 : 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 12,
                            decoration: BoxDecoration(
                              color: c.text,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const Spacer(),
                          if (selected)
                            Container(
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
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 64,
                          height: 84,
                          padding: const EdgeInsets.all(8),
                          alignment: Alignment.topLeft,
                          decoration: BoxDecoration(
                            color: c.surface2,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ColoredBox(
                                  color: c.accent,
                                  child: const SizedBox(width: 14, height: 10),
                                ),
                                ColoredBox(
                                  color: c.accent2,
                                  child: const SizedBox(width: 14, height: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 38,
                      color: c.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: c.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: c.text2,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              entry.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
