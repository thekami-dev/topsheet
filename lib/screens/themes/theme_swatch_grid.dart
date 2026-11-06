import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/app_themes.dart';
import '../../core/motion.dart';
import '../../widgets/pressable.dart';

class ThemeEntry {
  final String id;
  final String name;
  final PaletteColors colors;

  /// 3 hand-picked swatch colours: [background tone, accent, accent 2].
  final List<Color> preview;
  const ThemeEntry(this.id, this.name, this.colors, this.preview);
}

/// Grid of round swatches, evenly spaced; columns adapt to the width.
class ThemeGrid extends StatelessWidget {
  static const _minCellW = 72.0;

  final List<ThemeEntry> entries;
  final String current;

  const ThemeGrid({super.key, required this.entries, required this.current});

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
                      applyThemePalette(e.id);
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

/// One round swatch: a single disc split into 3 pie wedges.
/// Selected = accent ring around the whole disc + small check badge.
class _ThemeSwatch extends StatelessWidget {
  /// Outer size, ring included. The disc itself is 50 (60 - 2 * (3 + 2)).
  static const size = 60.0;

  final ThemeEntry entry;
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
    final gap = Theme.of(context).scaffoldBackgroundColor;

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
                child: CustomPaint(
                  painter: _TriSwatchPainter(
                    c0: entry.preview[0],
                    c1: entry.preview[1],
                    c2: entry.preview[2],
                    outline: c.border,
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
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: gap, width: 2),
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedTick02,
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

/// Paints one disc made of three 120° wedges. Boundaries form a "Y":
/// c0 = top wedge, c1 = lower-right wedge, c2 = lower-left wedge.
class _TriSwatchPainter extends CustomPainter {
  final Color c0;
  final Color c1;
  final Color c2;
  final Color outline;

  const _TriSwatchPainter({
    required this.c0,
    required this.c1,
    required this.c2,
    required this.outline,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: r);
    const sweep = 2 * math.pi / 3;
    const start = -5 * math.pi / 6;

    canvas.save();
    canvas.clipPath(Path()..addOval(rect));

    // Base disc in c0, then wedges 1 and 2 on top. Wedge 1 runs slightly
    // under wedge 2 so the shared edge never shows a hairline seam.
    canvas.drawCircle(center, r, Paint()..color = c0);
    canvas.drawArc(
      rect,
      start + sweep,
      sweep + 0.03,
      true,
      Paint()..color = c1,
    );
    canvas.drawArc(rect, start + 2 * sweep, sweep, true, Paint()..color = c2);
    canvas.restore();

    canvas.drawCircle(
      center,
      r - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = outline,
    );
  }

  @override
  bool shouldRepaint(_TriSwatchPainter old) =>
      old.c0 != c0 ||
      old.c1 != c1 ||
      old.c2 != c2 ||
      old.outline != outline;
}
