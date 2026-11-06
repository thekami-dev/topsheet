import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_themes.dart';
import '../core/theme_previews.dart';
import '../main.dart' show themeModeNotifier, applyThemeMode;
import 'settings/settings_widgets.dart';
import 'themes/theme_swatch_grid.dart';

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

    return DynamicColorBuilder(
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
            final entries = <ThemeEntry>[
              for (final p in kPalettes)
                ThemeEntry(
                  p.id,
                  p.name,
                  tone(isDark ? p.dark : p.light),
                  themePreviewColors(
                    id: p.id,
                    isDark: isDark,
                    base: isDark ? p.dark : p.light,
                    pureBlack: black,
                  ),
                ),
            ];
            if (dyn != null) {
              final dynColors = paletteFromScheme(dyn);
              entries.insert(
                1,
                ThemeEntry(
                  dynamicPaletteId,
                  'Dynamic',
                  tone(dynColors),
                  themePreviewColors(
                    id: dynamicPaletteId,
                    isDark: isDark,
                    base: dynColors,
                    pureBlack: black,
                  ),
                ),
              );
            }
            final currentName = entries
                .firstWhere(
                  (e) => e.id == current,
                  orElse: () => entries.first,
                )
                .name;

            return SettingsPage(
              title: 'Themes',
              children: [
                const SettingsSection('Appearance'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeModeNotifier,
                    builder: (context, mode, _) {
                      return SegmentedButton<ThemeMode>(
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
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('Pure black dark mode'),
                  subtitle: const Text(
                    'True black background in dark mode. '
                    'Saves battery on AMOLED screens.',
                  ),
                  value: black,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    applyThemePureBlack(v);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    children: [
                      Text(
                        'Color theme',
                        style: textTheme.titleSmall?.copyWith(
                          color: scheme.primary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        currentName,
                        style: textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ThemeGrid(entries: entries, current: current),
                ),
                if (dyn != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
    );
  }
}
