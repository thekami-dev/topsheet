import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Circular theme switch: the new theme grows out of the tapped control.
///
/// Why it is smooth: the app is captured twice (before and after the theme
/// change, the change itself happens while the old picture covers the
/// screen). The animation then only draws two static pictures, one of them
/// clipped by a growing circle, so nothing is rebuilt while it runs.
class ThemeReveal {
  ThemeReveal._();
  static final ThemeReveal instance = ThemeReveal._();

  static const duration = Duration(milliseconds: 650);
  static const curve = Curves.easeInOutCubicEmphasized;

  final GlobalKey _boundaryKey = GlobalKey();
  _ThemeRevealHostState? _host;

  /// True while a reveal is on screen. MaterialApp's own cross-fade is
  /// switched off during that time so the two never fight.
  bool get running => _host?._running ?? false;

  /// Runs [change] (which must switch the theme) with a circular reveal
  /// that starts at [origin] (global coordinates).
  Future<void> run(Offset origin, VoidCallback change) {
    final host = _host;
    if (host == null) {
      change();
      return Future.value();
    }
    return host._start(origin, change);
  }
}

/// Place once, directly above the app's Navigator (MaterialApp.builder).
class ThemeRevealHost extends StatefulWidget {
  final Widget child;
  const ThemeRevealHost({super.key, required this.child});

  @override
  State<ThemeRevealHost> createState() => _ThemeRevealHostState();
}

class _ThemeRevealHostState extends State<ThemeRevealHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: ThemeReveal.duration,
  );

  ui.Image? _old;
  ui.Image? _new;
  Offset _origin = Offset.zero;
  bool _busy = false;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    ThemeReveal.instance._host = this;
  }

  @override
  void dispose() {
    if (ThemeReveal.instance._host == this) {
      ThemeReveal.instance._host = null;
    }
    _old?.dispose();
    _new?.dispose();
    _c.dispose();
    super.dispose();
  }

  bool get _reduced => WidgetsBinding
      .instance
      .platformDispatcher
      .accessibilityFeatures
      .disableAnimations;

  Future<ui.Image?> _capture() async {
    final boundary =
        ThemeReveal.instance._boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    try {
      return await boundary.toImage(
        pixelRatio: MediaQuery.devicePixelRatioOf(context),
      );
    } catch (_) {
      return null;
    }
  }

  void _finish() {
    final o = _old;
    final n = _new;
    if (mounted) {
      setState(() {
        _old = null;
        _new = null;
        _running = false;
        _busy = false;
      });
    }
    o?.dispose();
    n?.dispose();
  }

  Future<void> _start(Offset globalOrigin, VoidCallback change) async {
    if (_busy || _reduced) {
      change();
      return;
    }
    _busy = true;

    // 1) Picture of the current (old) theme.
    final oldImage = await _capture();
    if (oldImage == null || !mounted) {
      oldImage?.dispose();
      _busy = false;
      change();
      return;
    }

    // 2) Put it on top so the change below is invisible.
    final box = context.findRenderObject() as RenderBox;
    setState(() {
      _old = oldImage;
      _new = null;
      _origin = box.globalToLocal(globalOrigin);
      _running = true;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    // 3) Switch the theme underneath and let it settle.
    change();
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    // 4) Picture of the new theme.
    final newImage = await _capture();
    if (newImage == null || !mounted) {
      newImage?.dispose();
      _finish();
      return;
    }
    setState(() => _new = newImage);

    // 5) Grow the circle.
    _c.value = 0;
    await _c.forward();
    _finish();
  }

  @override
  Widget build(BuildContext context) {
    final old = _old;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          key: ThemeReveal.instance._boundaryKey,
          child: widget.child,
        ),
        if (old != null)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) => CustomPaint(
                    painter: _RevealPainter(
                      oldImage: old,
                      newImage: _new,
                      origin: _origin,
                      progress: ThemeReveal.curve.transform(_c.value),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RevealPainter extends CustomPainter {
  final ui.Image oldImage;
  final ui.Image? newImage;
  final Offset origin;
  final double progress;

  const _RevealPainter({
    required this.oldImage,
    required this.newImage,
    required this.origin,
    required this.progress,
  });

  void _draw(Canvas canvas, ui.Image image, Rect dst) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      dst,
      Paint()..filterQuality = FilterQuality.low,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    final next = newImage;
    if (next == null) {
      _draw(canvas, oldImage, full);
      return;
    }
    if (progress >= 1) {
      _draw(canvas, next, full);
      return;
    }
    final maxRadius = [
      (origin - full.topLeft).distance,
      (origin - full.topRight).distance,
      (origin - full.bottomLeft).distance,
      (origin - full.bottomRight).distance,
    ].reduce(math.max);

    _draw(canvas, oldImage, full);
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: origin, radius: maxRadius * progress)),
    );
    _draw(canvas, next, full);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RevealPainter old) =>
      old.progress != progress ||
      old.newImage != newImage ||
      old.oldImage != oldImage ||
      old.origin != origin;
}
