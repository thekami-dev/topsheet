import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Tiny dots that drift around like stars, link up with faint lines, then
/// all fly in and settle into a sheet of paper with a folded corner (the
/// Topsheet mark).
///
/// Everything is derived from [progress] (0..1), so one controller drives
/// the whole intro and the painter never needs `setState`.
class SheetDotsPainter extends CustomPainter {
  SheetDotsPainter({
    required this.progress,
    required this.sheet,
    required this.primary,
    required this.muted,
  }) : super(repaint: progress);

  final Animation<double> progress;

  /// Where the finished sheet sits (its height must be 1.25 x its width).
  final Rect sheet;
  final Color primary;
  final Color muted;

  static const double _spacing = 0.14;
  static const double _linkDistance = 84;
  static const int _interiorCount = 22;

  /// Lines of the sheet in unit space (x 0..1, y 0..1.25). Dots end up
  /// evenly spaced along these; the flag says whether the end point gets
  /// its own dot (otherwise the next segment's start provides it).
  static const List<(Offset, Offset, bool)> _segments = [
    (Offset(0, 0), Offset(0.68, 0), false), // top
    (Offset(0.68, 0), Offset(1, 0.32), false), // folded corner, outer
    (Offset(1, 0.32), Offset(1, 1.25), false), // right
    (Offset(1, 1.25), Offset(0, 1.25), false), // bottom
    (Offset(0, 1.25), Offset(0, 0), false), // left
    (Offset(0.68, 0), Offset(0.68, 0.32), false), // flap, vertical
    (Offset(0.68, 0.32), Offset(1, 0.32), false), // flap, horizontal
    (Offset(0.2, 0.62), Offset(0.8, 0.62), true), // text line 1
    (Offset(0.2, 0.84), Offset(0.8, 0.84), true), // text line 2
    (Offset(0.2, 1.04), Offset(0.55, 1.04), true), // text line 3
  ];

  static final List<_Star> _stars = _buildStars();

  static List<_Star> _buildStars() {
    final random = math.Random(21);
    final targets = <(Offset, bool)>[];

    for (final (a, b, includeEnd) in _segments) {
      final n = math.max(1, ((b - a).distance / _spacing).round());
      final count = includeEnd ? n + 1 : n;
      for (var k = 0; k < count; k++) {
        targets.add((Offset.lerp(a, b, k / n)!, false));
      }
    }

    var interior = 0;
    var guard = 0;
    while (interior < _interiorCount && guard++ < 500) {
      final p = Offset(
        0.1 + random.nextDouble() * 0.8,
        0.12 + random.nextDouble() * 1.0,
      );
      if (p.dx > 0.66 && p.dy < 0.34) continue; // keep clear of the flap
      targets.add((p, true));
      interior++;
    }

    double between(double lo, double hi) => lo + random.nextDouble() * (hi - lo);
    return [
      for (final (target, inner) in targets)
        _Star(
          start: Offset(random.nextDouble(), random.nextDouble()),
          target: target,
          interior: inner,
          phaseX: between(0, math.pi * 2),
          phaseY: between(0, math.pi * 2),
          freqX: between(5, 12),
          freqY: between(5, 12),
          amp: between(12, 26),
          radius: between(1.1, 2.4),
          twinkleSpeed: between(10, 26),
          twinklePhase: between(0, math.pi * 2),
          delay: between(0, 0.35),
        ),
    ];
  }

  static double _ease(double x) =>
      Curves.easeInOutCubic.transform(x.clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final show = _ease(t / 0.1); // stars fade in
    if (show <= 0) return;
    final raw = ((t - 0.34) / 0.46).clamp(0.0, 1.0); // gathering window
    final gather = _ease(raw);
    final linked = _ease((t - 0.70) / 0.16); // outline draws itself
    final filled = _ease((t - 0.82) / 0.14); // paper fills in

    final arrive = List<double>.filled(_stars.length, 0);
    final points = List<Offset>.filled(_stars.length, Offset.zero);
    for (var i = 0; i < _stars.length; i++) {
      final s = _stars[i];
      final g = _ease((raw - s.delay) / 0.65);
      arrive[i] = g;
      final wobble =
          Offset(
            math.sin(t * s.freqX + s.phaseX),
            math.cos(t * s.freqY + s.phaseY),
          ) *
          (s.amp * (1 - g));
      final from =
          Offset(s.start.dx * size.width, s.start.dy * size.height) + wobble;
      final to = Offset(
        sheet.left + s.target.dx * sheet.width,
        sheet.top + s.target.dy * sheet.width,
      );
      points[i] = Offset.lerp(from, to, g)!;
    }

    _paintProximityLinks(canvas, points, show * (1 - gather));
    if (filled > 0) _paintPaper(canvas, filled);
    if (linked > 0) _paintEdges(canvas, linked);
    _paintDots(canvas, points, arrive, t, show, filled);
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
          alpha: 0.3 * alpha * (1 - d / _linkDistance),
        );
        canvas.drawLine(p[i], p[j], paint);
      }
    }
  }

  Offset _onSheet(Offset unit) => Offset(
    sheet.left + unit.dx * sheet.width,
    sheet.top + unit.dy * sheet.width,
  );

  void _paintPaper(Canvas canvas, double amount) {
    final body = Path()
      ..moveTo(_onSheet(const Offset(0, 0)).dx, _onSheet(const Offset(0, 0)).dy)
      ..lineTo(_onSheet(const Offset(0.68, 0)).dx, _onSheet(const Offset(0.68, 0)).dy)
      ..lineTo(_onSheet(const Offset(1, 0.32)).dx, _onSheet(const Offset(1, 0.32)).dy)
      ..lineTo(_onSheet(const Offset(1, 1.25)).dx, _onSheet(const Offset(1, 1.25)).dy)
      ..lineTo(_onSheet(const Offset(0, 1.25)).dx, _onSheet(const Offset(0, 1.25)).dy)
      ..close();
    canvas.drawPath(
      body,
      Paint()..color = primary.withValues(alpha: 0.14 * amount),
    );
    final flap = Path()
      ..moveTo(_onSheet(const Offset(0.68, 0)).dx, _onSheet(const Offset(0.68, 0)).dy)
      ..lineTo(_onSheet(const Offset(0.68, 0.32)).dx, _onSheet(const Offset(0.68, 0.32)).dy)
      ..lineTo(_onSheet(const Offset(1, 0.32)).dx, _onSheet(const Offset(1, 0.32)).dy)
      ..close();
    canvas.drawPath(
      flap,
      Paint()..color = primary.withValues(alpha: 0.32 * amount),
    );
  }

  void _paintEdges(Canvas canvas, double amount) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = primary.withValues(alpha: 0.9 * amount);
    for (final (a, b, _) in _segments) {
      final from = _onSheet(a);
      canvas.drawLine(from, Offset.lerp(from, _onSheet(b), amount)!, paint);
    }
  }

  void _paintDots(
    Canvas canvas,
    List<Offset> points,
    List<double> arrive,
    double t,
    double show,
    double filled,
  ) {
    final paint = Paint();
    for (var i = 0; i < points.length; i++) {
      final s = _stars[i];
      final g = arrive[i];
      final twinkle = 0.55 + 0.45 * math.sin(t * s.twinkleSpeed + s.twinklePhase);
      var alpha = show * (twinkle * (1 - g) + g);
      if (s.interior) alpha *= 1 - filled;
      if (alpha <= 0.01) continue;
      paint.color = Color.lerp(muted, primary, g)!.withValues(alpha: alpha);
      final radius = s.radius + ((s.interior ? 1.6 : 2.8) - s.radius) * g;
      canvas.drawCircle(points[i], radius, paint);
    }
  }

  @override
  bool shouldRepaint(SheetDotsPainter old) =>
      old.sheet != sheet || old.primary != primary || old.muted != muted;
}

/// One drifting dot: where it starts on screen (as a fraction), where it
/// ends up on the sheet (unit space) and how it moves in between.
class _Star {
  const _Star({
    required this.start,
    required this.target,
    required this.interior,
    required this.phaseX,
    required this.phaseY,
    required this.freqX,
    required this.freqY,
    required this.amp,
    required this.radius,
    required this.twinkleSpeed,
    required this.twinklePhase,
    required this.delay,
  });

  final Offset start;
  final Offset target;
  final bool interior;
  final double phaseX;
  final double phaseY;
  final double freqX;
  final double freqY;
  final double amp;
  final double radius;
  final double twinkleSpeed;
  final double twinklePhase;
  final double delay;
}
