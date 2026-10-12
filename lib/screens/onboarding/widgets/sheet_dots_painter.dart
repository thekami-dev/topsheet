import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Floating dots that drift, link up with thin lines, and settle into a
/// sheet of paper with a folded corner (the Topsheet mark).
///
/// Everything is derived from [progress] (0..1), so one controller drives
/// the whole intro and the painter never needs `setState`.
class SheetDotsPainter extends CustomPainter {
  SheetDotsPainter({
    required this.progress,
    required this.primary,
    required this.muted,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color primary;
  final Color muted;

  static const double _sheetWidth = 92;
  static const double _sheetHeight = _sheetWidth * 1.25;
  static const double _sheetLeft = 28;
  static const double _sheetBottomGap = 16;
  static const double _linkDistance = 96;
  static const int _ambientCount = 18;

  /// Points that end up on the sheet, in unit space (x 0..1, y 0..1.25).
  static const List<Offset> _marks = [
    Offset(0, 0), // 0  top-left
    Offset(0.68, 0), // 1  fold start
    Offset(1, 0.32), // 2  fold end
    Offset(1, 1.25), // 3  bottom-right
    Offset(0, 1.25), // 4  bottom-left
    Offset(0.68, 0.32), // 5  fold inner corner
    Offset(0.2, 0.62), // 6  text line 1
    Offset(0.8, 0.62), // 7
    Offset(0.2, 0.84), // 8  text line 2
    Offset(0.8, 0.84), // 9
    Offset(0.2, 1.04), // 10 text line 3
    Offset(0.55, 1.04), // 11
    Offset(0, 0.625), // 12 left edge
    Offset(0.5, 1.25), // 13 bottom edge
    Offset(1, 0.785), // 14 right edge
    Offset(0.34, 0), // 15 top edge
  ];

  /// Which marks get joined by a line once the dots have gathered.
  static const List<(int, int)> _edges = [
    (0, 1), (1, 2), (2, 3), (3, 4), (4, 0), // outline
    (1, 5), (5, 2), // folded corner
    (6, 7), (8, 9), (10, 11), // text lines
  ];

  static final List<Offset> _starts = _scatter(_marks.length + _ambientCount);
  static final List<double> _phases = _spread(_marks.length + _ambientCount);

  static List<Offset> _scatter(int n) {
    final random = math.Random(11);
    return List.generate(n, (_) => Offset(random.nextDouble(), random.nextDouble()));
  }

  static List<double> _spread(int n) {
    final random = math.Random(5);
    return List.generate(n, (_) => random.nextDouble() * math.pi * 2);
  }

  static double _ease(double x) =>
      Curves.easeInOutCubic.transform(x.clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final show = _ease(t / 0.18); // dots fade in
    final gather = _ease((t - 0.26) / 0.46); // dots travel to the sheet
    final linked = _ease((t - 0.62) / 0.20); // outline draws itself
    final filled = _ease((t - 0.78) / 0.18); // paper fills in
    if (show <= 0) return;

    final sheet = Rect.fromLTWH(
      _sheetLeft,
      size.height - _sheetHeight - _sheetBottomGap,
      _sheetWidth,
      _sheetHeight,
    );
    final points = _positions(size, sheet, t, gather);

    _paintProximityLinks(canvas, points, show * (1 - linked));
    if (filled > 0) _paintPaper(canvas, points, filled);
    if (linked > 0) _paintEdges(canvas, points, linked);
    _paintDots(canvas, points, show, gather);
  }

  List<Offset> _positions(Size size, Rect sheet, double t, double gather) {
    final out = List<Offset>.filled(_starts.length, Offset.zero);
    for (var i = 0; i < _starts.length; i++) {
      final s = _starts[i];
      final wobble = Offset(
        math.sin(t * 6.2 + _phases[i]),
        math.cos(t * 5.1 + _phases[i] * 1.7),
      );
      final start =
          Offset(s.dx * size.width, s.dy * size.height) +
          wobble * (10 * (1 - gather));
      if (i < _marks.length) {
        final m = _marks[i];
        final target = Offset(
          sheet.left + m.dx * sheet.width,
          sheet.top + m.dy * sheet.width,
        );
        out[i] = Offset.lerp(start, target, gather)!;
      } else {
        out[i] = start;
      }
    }
    return out;
  }

  void _paintProximityLinks(Canvas canvas, List<Offset> p, double alpha) {
    if (alpha <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < p.length; i++) {
      for (var j = i + 1; j < p.length; j++) {
        final d = (p[i] - p[j]).distance;
        if (d >= _linkDistance) continue;
        paint.color = muted.withValues(
          alpha: 0.35 * alpha * (1 - d / _linkDistance),
        );
        canvas.drawLine(p[i], p[j], paint);
      }
    }
  }

  void _paintPaper(Canvas canvas, List<Offset> p, double amount) {
    final body = Path()
      ..moveTo(p[0].dx, p[0].dy)
      ..lineTo(p[1].dx, p[1].dy)
      ..lineTo(p[2].dx, p[2].dy)
      ..lineTo(p[3].dx, p[3].dy)
      ..lineTo(p[4].dx, p[4].dy)
      ..close();
    canvas.drawPath(
      body,
      Paint()..color = primary.withValues(alpha: 0.14 * amount),
    );
    final flap = Path()
      ..moveTo(p[1].dx, p[1].dy)
      ..lineTo(p[5].dx, p[5].dy)
      ..lineTo(p[2].dx, p[2].dy)
      ..close();
    canvas.drawPath(
      flap,
      Paint()..color = primary.withValues(alpha: 0.32 * amount),
    );
  }

  void _paintEdges(Canvas canvas, List<Offset> p, double amount) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = primary.withValues(alpha: 0.9 * amount);
    for (final (a, b) in _edges) {
      canvas.drawLine(p[a], Offset.lerp(p[a], p[b], amount)!, paint);
    }
  }

  void _paintDots(Canvas canvas, List<Offset> p, double show, double gather) {
    final paint = Paint();
    for (var i = 0; i < p.length; i++) {
      final isMark = i < _marks.length;
      final alpha = isMark ? show : show * (1 - gather);
      if (alpha <= 0) continue;
      paint.color = primary.withValues(alpha: (isMark ? 1.0 : 0.55) * alpha);
      canvas.drawCircle(p[i], isMark ? 3.2 : 2.2, paint);
    }
  }

  @override
  bool shouldRepaint(SheetDotsPainter old) =>
      old.primary != primary || old.muted != muted;
}
