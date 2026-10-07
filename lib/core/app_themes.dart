import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart' show AppColors, AppColorsLight;

/// Colours one palette needs for one brightness (dark or light).
class PaletteColors {
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color text;
  final Color text2;
  final Color accent;
  final Color accent2;
  final Color success;
  final Color error;

  /// Text/icon colour drawn on top of [accent] (buttons, FAB).
  final Color onAccent;

  PaletteColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.text,
    required this.text2,
    required this.accent,
    required this.accent2,
    required this.success,
    required this.error,
    Color? onAccent,
  }) : onAccent =
           onAccent ??
           (accent.computeLuminance() > 0.45
               ? const Color(0xFF14141A)
               : Colors.white);
}

class AppPalette {
  final String id;
  final String name;
  final PaletteColors dark;
  final PaletteColors light;

  AppPalette({
    required this.id,
    required this.name,
    required this.dark,
    required this.light,
  });
}

/// Wallpaper-based palette (Android 12+). Not in [kPalettes] because its
/// colours come from the system at runtime.
const dynamicPaletteId = 'dynamic';

final _defaultPalette = AppPalette(
  id: 'default',
  name: 'Default',
  dark: PaletteColors(
    bg: AppColors.bg,
    surface: AppColors.surface,
    surface2: AppColors.surface2,
    border: AppColors.border,
    text: AppColors.text,
    text2: AppColors.text2,
    accent: AppColors.accent,
    accent2: AppColors.accent2,
    success: AppColors.success,
    error: AppColors.error,
    onAccent: Colors.white,
  ),
  light: PaletteColors(
    bg: AppColorsLight.bg,
    surface: AppColorsLight.surface,
    surface2: AppColorsLight.surface2,
    border: AppColorsLight.border,
    text: AppColorsLight.text,
    text2: AppColorsLight.text2,
    accent: AppColorsLight.accent,
    accent2: AppColorsLight.accent2,
    success: AppColorsLight.success,
    error: AppColorsLight.error,
    onAccent: Colors.white,
  ),
);

final _catppuccin = AppPalette(
  id: 'catppuccin',
  name: 'Catppuccin',
  dark: PaletteColors(
    bg: const Color(0xFF181825),
    surface: const Color(0xFF1E1E2E),
    surface2: const Color(0xFF313244),
    border: const Color(0xFF45475A),
    text: const Color(0xFFCDD6F4),
    text2: const Color(0xFFA6ADC8),
    accent: const Color(0xFFCBA6F7),
    accent2: const Color(0xFFB4BEFE),
    success: const Color(0xFFA6E3A1),
    error: const Color(0xFFF38BA8),
  ),
  light: PaletteColors(
    bg: const Color(0xFFEFF1F5),
    surface: const Color(0xFFE6E9EF),
    surface2: const Color(0xFFDCE0E8),
    border: const Color(0xFFCCD0DA),
    text: const Color(0xFF4C4F69),
    text2: const Color(0xFF6C6F85),
    accent: const Color(0xFF8839EF),
    accent2: const Color(0xFF8839EF),
    success: const Color(0xFF40A02B),
    error: const Color(0xFFD20F39),
  ),
);

final _greenApple = AppPalette(
  id: 'green_apple',
  name: 'Green Apple',
  dark: PaletteColors(
    bg: const Color(0xFF101510),
    surface: const Color(0xFF171D17),
    surface2: const Color(0xFF1F271F),
    border: const Color(0xFF2E3A2E),
    text: const Color(0xFFE3EBDD),
    text2: const Color(0xFF9AA894),
    accent: const Color(0xFF7DDE92),
    accent2: const Color(0xFF7DDE92),
    success: const Color(0xFF7DDE92),
    error: const Color(0xFFFF8A80),
  ),
  light: PaletteColors(
    bg: const Color(0xFFF5FAF2),
    surface: const Color(0xFFFFFFFF),
    surface2: const Color(0xFFE8F1E4),
    border: const Color(0xFFD3E0CE),
    text: const Color(0xFF151D14),
    text2: const Color(0xFF546350),
    accent: const Color(0xFF2E9E4B),
    accent2: const Color(0xFF1E7D36),
    success: const Color(0xFF1E7D36),
    error: const Color(0xFFD33A3A),
  ),
);

final _nord = AppPalette(
  id: 'nord',
  name: 'Nord',
  dark: PaletteColors(
    bg: const Color(0xFF2E3440),
    surface: const Color(0xFF3B4252),
    surface2: const Color(0xFF434C5E),
    border: const Color(0xFF4C566A),
    text: const Color(0xFFECEFF4),
    text2: const Color(0xFFAEB8CC),
    accent: const Color(0xFF88C0D0),
    accent2: const Color(0xFF88C0D0),
    success: const Color(0xFFA3BE8C),
    error: const Color(0xFFBF616A),
  ),
  light: PaletteColors(
    bg: const Color(0xFFECEFF4),
    surface: const Color(0xFFFFFFFF),
    surface2: const Color(0xFFE5E9F0),
    border: const Color(0xFFD8DEE9),
    text: const Color(0xFF2E3440),
    text2: const Color(0xFF5E6A80),
    accent: const Color(0xFF5E81AC),
    accent2: const Color(0xFF4C6A94),
    success: const Color(0xFF5E8C3F),
    error: const Color(0xFFB3404B),
  ),
);

final _tokyoNight = AppPalette(
  id: 'tokyo_night',
  name: 'Tokyo Night',
  dark: PaletteColors(
    bg: const Color(0xFF1A1B26),
    surface: const Color(0xFF1F2335),
    surface2: const Color(0xFF24283B),
    border: const Color(0xFF343A55),
    text: const Color(0xFFC0CAF5),
    text2: const Color(0xFF9AA5CE),
    accent: const Color(0xFF7AA2F7),
    accent2: const Color(0xFF7DCFFF),
    success: const Color(0xFF9ECE6A),
    error: const Color(0xFFF7768E),
  ),
  light: PaletteColors(
    bg: const Color(0xFFE6E7ED),
    surface: const Color(0xFFF2F3F7),
    surface2: const Color(0xFFDADCE6),
    border: const Color(0xFFC8CBD9),
    text: const Color(0xFF343B58),
    text2: const Color(0xFF6C6E8A),
    accent: const Color(0xFF2E7DE9),
    accent2: const Color(0xFF2468C9),
    success: const Color(0xFF587539),
    error: const Color(0xFFC64343),
  ),
);

final _monochrome = AppPalette(
  id: 'monochrome',
  name: 'Monochrome',
  dark: PaletteColors(
    bg: const Color(0xFF000000),
    surface: const Color(0xFF0E0E0E),
    surface2: const Color(0xFF1A1A1A),
    border: const Color(0xFF2E2E2E),
    text: const Color(0xFFFFFFFF),
    text2: const Color(0xFFA0A0A0),
    accent: const Color(0xFFFFFFFF),
    accent2: const Color(0xFFFFFFFF),
    success: const Color(0xFFB6E3B6),
    error: const Color(0xFFFF6B6B),
  ),
  light: PaletteColors(
    bg: const Color(0xFFFFFFFF),
    surface: const Color(0xFFF5F5F5),
    surface2: const Color(0xFFEBEBEB),
    border: const Color(0xFFDADADA),
    text: const Color(0xFF000000),
    text2: const Color(0xFF5F5F5F),
    accent: const Color(0xFF000000),
    accent2: const Color(0xFF000000),
    success: const Color(0xFF2E7D32),
    error: const Color(0xFFC62828),
  ),
);

/// Built-in palettes, in display order. The first one is the fallback.
final List<AppPalette> kPalettes = [
  _defaultPalette,
  _catppuccin,
  _greenApple,
  _nord,
  _tokyoNight,
  _monochrome,
];

/// Maps a system (Material You) scheme onto our palette shape.
PaletteColors paletteFromScheme(ColorScheme s) => PaletteColors(
  bg: s.surface,
  surface: s.surfaceContainer,
  surface2: s.surfaceContainerHigh,
  border: s.outlineVariant,
  text: s.onSurface,
  text2: s.onSurfaceVariant,
  accent: s.primary,
  accent2: s.primary,
  success: s.tertiary,
  error: s.error,
  onAccent: s.onPrimary,
);

PaletteColors resolvePalette(
  String id,
  bool isDark, {
  ColorScheme? dynamicScheme,
}) {
  if (id == dynamicPaletteId && dynamicScheme != null) {
    return paletteFromScheme(dynamicScheme);
  }
  final p = kPalettes.firstWhere(
    (p) => p.id == id,
    orElse: () => kPalettes.first,
  );
  return isDark ? p.dark : p.light;
}

/// Currently selected palette id. MaterialApp listens to this.
final themePaletteNotifier = ValueNotifier<String>('default');

const _kPaletteKey = 'themePalette';

Future<void> loadThemePalette() async {
  final prefs = await SharedPreferences.getInstance();
  themePaletteNotifier.value = prefs.getString(_kPaletteKey) ?? 'default';
}

Future<void> applyThemePalette(String id) async {
  themePaletteNotifier.value = id;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kPaletteKey, id);
}
