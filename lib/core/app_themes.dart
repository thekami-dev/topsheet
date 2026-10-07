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

final _dracula = AppPalette(
  id: 'dracula',
  name: 'Dracula',
  dark: PaletteColors(
    bg: const Color(0xFF21222C),
    surface: const Color(0xFF282A36),
    surface2: const Color(0xFF343746),
    border: const Color(0xFF44475A),
    text: const Color(0xFFF8F8F2),
    text2: const Color(0xFFB0B5CF),
    accent: const Color(0xFFBD93F9),
    accent2: const Color(0xFFFF79C6),
    success: const Color(0xFF50FA7B),
    error: const Color(0xFFFF5555),
    onAccent: const Color(0xFF282A36),
  ),
  // Alucard, Dracula's official light variant.
  light: PaletteColors(
    bg: const Color(0xFFFFFBEB),
    surface: const Color(0xFFFFFFFF),
    surface2: const Color(0xFFF3EEDA),
    border: const Color(0xFFDAD5C0),
    text: const Color(0xFF1F1F1F),
    text2: const Color(0xFF5F5C4B),
    accent: const Color(0xFF644AC9),
    accent2: const Color(0xFFA3144D),
    success: const Color(0xFF14710A),
    error: const Color(0xFFCB3A2A),
  ),
);

final _gruvbox = AppPalette(
  id: 'gruvbox',
  name: 'Gruvbox',
  dark: PaletteColors(
    bg: const Color(0xFF1D2021),
    surface: const Color(0xFF282828),
    surface2: const Color(0xFF3C3836),
    border: const Color(0xFF504945),
    text: const Color(0xFFEBDBB2),
    text2: const Color(0xFFA89984),
    accent: const Color(0xFFFABD2F),
    accent2: const Color(0xFFFE8019),
    success: const Color(0xFFB8BB26),
    error: const Color(0xFFFB4934),
  ),
  light: PaletteColors(
    bg: const Color(0xFFFBF1C7),
    surface: const Color(0xFFF9F5D7),
    surface2: const Color(0xFFEBDBB2),
    border: const Color(0xFFD5C4A1),
    text: const Color(0xFF3C3836),
    text2: const Color(0xFF7C6F64),
    accent: const Color(0xFFAF3A03),
    accent2: const Color(0xFFB57614),
    success: const Color(0xFF79740E),
    error: const Color(0xFF9D0006),
  ),
);

final _rosePine = AppPalette(
  id: 'rose_pine',
  name: 'Rose Pine',
  dark: PaletteColors(
    bg: const Color(0xFF191724),
    surface: const Color(0xFF1F1D2E),
    surface2: const Color(0xFF26233A),
    border: const Color(0xFF403D52),
    text: const Color(0xFFE0DEF4),
    text2: const Color(0xFF908CAA),
    accent: const Color(0xFFEBBCBA),
    accent2: const Color(0xFFC4A7E7),
    success: const Color(0xFF9CCFD8),
    error: const Color(0xFFEB6F92),
  ),
  // Rosé Pine Dawn.
  light: PaletteColors(
    bg: const Color(0xFFFAF4ED),
    surface: const Color(0xFFFFFAF3),
    surface2: const Color(0xFFF2E9E1),
    border: const Color(0xFFDFDAD9),
    text: const Color(0xFF575279),
    text2: const Color(0xFF797593),
    accent: const Color(0xFF907AA9),
    accent2: const Color(0xFF907AA9),
    success: const Color(0xFF286983),
    error: const Color(0xFFB4637A),
  ),
);

final _everforest = AppPalette(
  id: 'everforest',
  name: 'Everforest',
  dark: PaletteColors(
    bg: const Color(0xFF232A2E),
    surface: const Color(0xFF2D353B),
    surface2: const Color(0xFF3D484D),
    border: const Color(0xFF475258),
    text: const Color(0xFFD3C6AA),
    text2: const Color(0xFF9DA9A0),
    accent: const Color(0xFFA7C080),
    accent2: const Color(0xFF83C092),
    success: const Color(0xFFA7C080),
    error: const Color(0xFFE67E80),
  ),
  light: PaletteColors(
    bg: const Color(0xFFFDF6E3),
    surface: const Color(0xFFF4F0D9),
    surface2: const Color(0xFFEFEBD4),
    border: const Color(0xFFE0DCC7),
    text: const Color(0xFF5C6A72),
    text2: const Color(0xFF707F78),
    accent: const Color(0xFF8DA101),
    accent2: const Color(0xFF35A77C),
    success: const Color(0xFF8DA101),
    error: const Color(0xFFF85552),
    onAccent: Colors.white,
  ),
);

final _kanagawa = AppPalette(
  id: 'kanagawa',
  name: 'Kanagawa',
  dark: PaletteColors(
    bg: const Color(0xFF16161D),
    surface: const Color(0xFF1F1F28),
    surface2: const Color(0xFF2A2A37),
    border: const Color(0xFF363646),
    text: const Color(0xFFDCD7BA),
    text2: const Color(0xFFA6A18A),
    accent: const Color(0xFF7E9CD8),
    accent2: const Color(0xFFE6C384),
    success: const Color(0xFF98BB6C),
    error: const Color(0xFFE46876),
    onAccent: const Color(0xFF1F1F28),
  ),
  // Kanagawa Lotus.
  light: PaletteColors(
    bg: const Color(0xFFF2ECBC),
    surface: const Color(0xFFE5DDB0),
    surface2: const Color(0xFFDCD5AC),
    border: const Color(0xFFD5CEA3),
    text: const Color(0xFF545464),
    text2: const Color(0xFF716E61),
    accent: const Color(0xFF4D699B),
    accent2: const Color(0xFF5D57A3),
    success: const Color(0xFF6F894E),
    error: const Color(0xFFC84053),
  ),
);

final _oneDark = AppPalette(
  id: 'one_dark',
  name: 'One Dark',
  dark: PaletteColors(
    bg: const Color(0xFF21252B),
    surface: const Color(0xFF282C34),
    surface2: const Color(0xFF353B45),
    border: const Color(0xFF3E4451),
    text: const Color(0xFFABB2BF),
    text2: const Color(0xFF828997),
    accent: const Color(0xFF61AFEF),
    accent2: const Color(0xFFC678DD),
    success: const Color(0xFF98C379),
    error: const Color(0xFFE06C75),
    onAccent: const Color(0xFF21252B),
  ),
  // One Light.
  light: PaletteColors(
    bg: const Color(0xFFFAFAFA),
    surface: const Color(0xFFFFFFFF),
    surface2: const Color(0xFFF0F0F1),
    border: const Color(0xFFDBDBDC),
    text: const Color(0xFF383A42),
    text2: const Color(0xFF696C77),
    accent: const Color(0xFF4078F2),
    accent2: const Color(0xFFA626A4),
    success: const Color(0xFF50A14F),
    error: const Color(0xFFE45649),
  ),
);

final _solarized = AppPalette(
  id: 'solarized',
  name: 'Solarized',
  dark: PaletteColors(
    bg: const Color(0xFF002B36),
    surface: const Color(0xFF073642),
    surface2: const Color(0xFF0D4350),
    border: const Color(0xFF355F6C),
    text: const Color(0xFFEEE8D5),
    text2: const Color(0xFF93A1A1),
    accent: const Color(0xFF268BD2),
    accent2: const Color(0xFFB58900),
    success: const Color(0xFF859900),
    error: const Color(0xFFDC322F),
  ),
  light: PaletteColors(
    bg: const Color(0xFFFDF6E3),
    surface: const Color(0xFFEEE8D5),
    surface2: const Color(0xFFE5DEC6),
    border: const Color(0xFFD8D0B8),
    text: const Color(0xFF073642),
    text2: const Color(0xFF586E75),
    accent: const Color(0xFF268BD2),
    accent2: const Color(0xFF268BD2),
    success: const Color(0xFF859900),
    error: const Color(0xFFDC322F),
  ),
);

final _ayu = AppPalette(
  id: 'ayu',
  name: 'Ayu',
  dark: PaletteColors(
    bg: const Color(0xFF0B0E14),
    surface: const Color(0xFF131721),
    surface2: const Color(0xFF1C212B),
    border: const Color(0xFF272D38),
    text: const Color(0xFFBFBDB6),
    text2: const Color(0xFF8A9199),
    accent: const Color(0xFFE6B450),
    accent2: const Color(0xFFFF8F40),
    success: const Color(0xFFAAD94C),
    error: const Color(0xFFF26D78),
  ),
  light: PaletteColors(
    bg: const Color(0xFFFCFCFC),
    surface: const Color(0xFFFFFFFF),
    surface2: const Color(0xFFF3F4F5),
    border: const Color(0xFFE0E2E4),
    text: const Color(0xFF5C6166),
    text2: const Color(0xFF787B80),
    accent: const Color(0xFFFA8D3E),
    accent2: const Color(0xFFD9730D),
    success: const Color(0xFF86B300),
    error: const Color(0xFFE65050),
    onAccent: const Color(0xFF14141A),
  ),
);

final _moonlight = AppPalette(
  id: 'moonlight',
  name: 'Moonlight',
  dark: PaletteColors(
    bg: const Color(0xFF1E2030),
    surface: const Color(0xFF222436),
    surface2: const Color(0xFF2F334D),
    border: const Color(0xFF3B4261),
    text: const Color(0xFFC8D3F5),
    text2: const Color(0xFF828BB8),
    accent: const Color(0xFFC099FF),
    accent2: const Color(0xFF82AAFF),
    success: const Color(0xFFC3E88D),
    error: const Color(0xFFFF757F),
    onAccent: const Color(0xFF1E2030),
  ),
  // Moonlight has no official light variant; this one keeps the same
  // blue/purple identity on a cool light base.
  light: PaletteColors(
    bg: const Color(0xFFECEEF8),
    surface: const Color(0xFFF7F8FD),
    surface2: const Color(0xFFE0E3F2),
    border: const Color(0xFFCBD0E6),
    text: const Color(0xFF2A2F55),
    text2: const Color(0xFF5B6290),
    accent: const Color(0xFF7C5CD6),
    accent2: const Color(0xFF3E6BD6),
    success: const Color(0xFF4A8F3A),
    error: const Color(0xFFD0455A),
  ),
);

final _github = AppPalette(
  id: 'github',
  name: 'GitHub',
  dark: PaletteColors(
    bg: const Color(0xFF0D1117),
    surface: const Color(0xFF161B22),
    surface2: const Color(0xFF21262D),
    border: const Color(0xFF30363D),
    text: const Color(0xFFE6EDF3),
    text2: const Color(0xFF8B949E),
    accent: const Color(0xFF2F81F7),
    accent2: const Color(0xFF58A6FF),
    success: const Color(0xFF3FB950),
    error: const Color(0xFFF85149),
  ),
  light: PaletteColors(
    bg: const Color(0xFFFFFFFF),
    surface: const Color(0xFFF6F8FA),
    surface2: const Color(0xFFEAEEF2),
    border: const Color(0xFFD0D7DE),
    text: const Color(0xFF1F2328),
    text2: const Color(0xFF656D76),
    accent: const Color(0xFF0969DA),
    accent2: const Color(0xFF0550AE),
    success: const Color(0xFF1A7F37),
    error: const Color(0xFFCF222E),
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
  _dracula,
  _gruvbox,
  _rosePine,
  _everforest,
  _kanagawa,
  _oneDark,
  _solarized,
  _ayu,
  _moonlight,
  _github,
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

PaletteColors _resolveBase(
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

/// True-black variant of [c] for AMOLED screens (dark mode only).
PaletteColors pureBlackOf(PaletteColors c) => PaletteColors(
  bg: const Color(0xFF000000),
  surface: Color.lerp(const Color(0xFF000000), c.surface, 0.55)!,
  surface2: Color.lerp(const Color(0xFF000000), c.surface2, 0.7)!,
  border: c.border,
  text: c.text,
  text2: c.text2,
  accent: c.accent,
  accent2: c.accent2,
  success: c.success,
  error: c.error,
  onAccent: c.onAccent,
);

PaletteColors resolvePalette(
  String id,
  bool isDark, {
  ColorScheme? dynamicScheme,
  bool pureBlack = false,
}) {
  final c = _resolveBase(id, isDark, dynamicScheme: dynamicScheme);
  return isDark && pureBlack ? pureBlackOf(c) : c;
}

final themePureBlackNotifier = ValueNotifier<bool>(false);

const _kPureBlackKey = 'themePureBlack';

Future<void> loadThemePureBlack() async {
  final prefs = await SharedPreferences.getInstance();
  themePureBlackNotifier.value = prefs.getBool(_kPureBlackKey) ?? false;
}

Future<void> applyThemePureBlack(bool value) async {
  themePureBlackNotifier.value = value;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kPureBlackKey, value);
}
