import 'package:flutter/material.dart';

import 'app_themes.dart' show PaletteColors;

/// Hand-picked 3-colour preview for one palette, per brightness.
///
/// Order is fixed: [0] = background tone (top wedge),
/// [1] = main accent, [2] = second signature colour.
class _Preview {
  final List<Color> dark;
  final List<Color> light;
  const _Preview(this.dark, this.light);
}

const Map<String, _Preview> _kPreviews = {
  'default': _Preview(
    [Color(0xFF1B1C22), Color(0xFF6C5CE7), Color(0xFF2ECC91)],
    [Color(0xFFF1F1F5), Color(0xFF6C5CE7), Color(0xFF1FA971)],
  ),
  'catppuccin': _Preview(
    [Color(0xFF313244), Color(0xFFCBA6F7), Color(0xFF89B4FA)],
    [Color(0xFFDCE0E8), Color(0xFF8839EF), Color(0xFF1E66F5)],
  ),
  'green_apple': _Preview(
    [Color(0xFF1F271F), Color(0xFF7DDE92), Color(0xFFC6F27A)],
    [Color(0xFFE8F1E4), Color(0xFF2E9E4B), Color(0xFFA5D86B)],
  ),
  'nord': _Preview(
    [Color(0xFF434C5E), Color(0xFF88C0D0), Color(0xFF81A1C1)],
    [Color(0xFFE5E9F0), Color(0xFF5E81AC), Color(0xFF88C0D0)],
  ),
  'tokyo_night': _Preview(
    [Color(0xFF24283B), Color(0xFF7AA2F7), Color(0xFFBB9AF7)],
    [Color(0xFFDADCE6), Color(0xFF2E7DE9), Color(0xFF9854F1)],
  ),
  'monochrome': _Preview(
    [Color(0xFF262626), Color(0xFF8C8C8C), Color(0xFFF5F5F5)],
    [Color(0xFFE6E6E6), Color(0xFF7A7A7A), Color(0xFF111111)],
  ),
  'dracula': _Preview(
    [Color(0xFF44475A), Color(0xFFBD93F9), Color(0xFFFF79C6)],
    [Color(0xFFF3EEDA), Color(0xFF644AC9), Color(0xFFA3144D)],
  ),
  'gruvbox': _Preview(
    [Color(0xFF3C3836), Color(0xFFFABD2F), Color(0xFFFE8019)],
    [Color(0xFFEBDBB2), Color(0xFFB57614), Color(0xFFAF3A03)],
  ),
  'rose_pine': _Preview(
    [Color(0xFF26233A), Color(0xFFEBBCBA), Color(0xFFC4A7E7)],
    [Color(0xFFF2E9E1), Color(0xFFD7827E), Color(0xFF907AA9)],
  ),
  'everforest': _Preview(
    [Color(0xFF3D484D), Color(0xFFA7C080), Color(0xFF83C092)],
    [Color(0xFFEFEBD4), Color(0xFF8DA101), Color(0xFF35A77C)],
  ),
  'kanagawa': _Preview(
    [Color(0xFF2A2A37), Color(0xFF7E9CD8), Color(0xFFE6C384)],
    [Color(0xFFDCD5AC), Color(0xFF4D699B), Color(0xFFCC6D00)],
  ),
  'one_dark': _Preview(
    [Color(0xFF353B45), Color(0xFF61AFEF), Color(0xFFC678DD)],
    [Color(0xFFF0F0F1), Color(0xFF4078F2), Color(0xFFA626A4)],
  ),
  'solarized': _Preview(
    [Color(0xFF073642), Color(0xFF268BD2), Color(0xFFB58900)],
    [Color(0xFFEEE8D5), Color(0xFF268BD2), Color(0xFFB58900)],
  ),
  'ayu': _Preview(
    [Color(0xFF1C212B), Color(0xFFE6B450), Color(0xFFFF8F40)],
    [Color(0xFFF3F4F5), Color(0xFFFA8D3E), Color(0xFF399EE6)],
  ),
  'moonlight': _Preview(
    [Color(0xFF2F334D), Color(0xFFC099FF), Color(0xFF82AAFF)],
    [Color(0xFFE0E3F2), Color(0xFF7C5CD6), Color(0xFF3E6BD6)],
  ),
  'github': _Preview(
    [Color(0xFF21262D), Color(0xFF2F81F7), Color(0xFF3FB950)],
    [Color(0xFFEAEEF2), Color(0xFF0969DA), Color(0xFF1A7F37)],
  ),
};

/// The 3 swatch colours for palette [id].
///
/// Palettes without a hand-picked entry (e.g. Dynamic, whose colours come
/// from the wallpaper) fall back to [base]. With pure-black dark mode the
/// background wedge becomes true black.
List<Color> themePreviewColors({
  required String id,
  required bool isDark,
  required PaletteColors base,
  bool pureBlack = false,
}) {
  final p = _kPreviews[id];
  final List<Color> c = p == null
      ? [base.surface2, base.accent, base.success]
      : (isDark ? p.dark : p.light);
  if (isDark && pureBlack) {
    return [const Color(0xFF000000), c[1], c[2]];
  }
  return c;
}
