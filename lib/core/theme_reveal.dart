import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Telegram-style theme switch: a circle grows from the tapped control and
/// reveals the new theme across the whole app.
///
/// How it stays smooth: ONE picture of the old UI is taken and laid over the
/// screen. In the same frame the theme is switched underneath and the circle
/// starts growing. The circle starts slowly on purpose: the one-time rebuild
/// for the new theme happens in those first frames, while the circle is still
/// tiny, so the hitch is invisible. After that each frame only draws one
/// static picture with a hole in it.
class ThemeReveal {
  ThemeReveal._();
  static final ThemeReveal instance = ThemeReveal._();

  static const duration = Duration(milliseconds: 600);
  static const curve = Curves.easeInOutCubic;

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

  ui.Image? _snap;
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
    _snap?.dispose();
    _c.dispose();
    super.dispose();
  }

  bool get _reduced => WidgetsBinding
      .instance
      .platformDispatcher
      .accessibilityFeatures
      .disableAnimations;

  Future<void> _start(Offset globalOrigin, VoidCallback change) async {
    if (_busy || _reduced) {
      change();
      return;
    }
    final boundary =
        ThemeReveal.instance._boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      change();
      return;
    }

    _busy = true;
    ui.Image? image;
    try {
      image = await boundary.toImage(
        pixelRatio: MediaQuery.devicePixelRatioOf(context),
      );
    } catch (_) {
      image = null;
    }
    if (image == null || !mounted) {
      image?.dispose();
      _busy = false;
      change();
      return;
    }

    final box = context.findRenderObject() as RenderBox;
    // Same frame: cover the screen with the old picture, switch the theme
    // underneath, start the circle.
    setState(() {
      _snap = image;
      _origin = box.globalToLocal(globalOrigin);
      _running = true;
    });
    change();
    _c.value = 0;
    await _c.forward();
    if (!mounted) return;

    final old = _snap;
    setState(() {
      _snap = null;
      _running = false;
      _busy = false;
    });
    old?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snap = _snap;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          key: ThemeReveal.instance._boundaryKey,
          child: widget.child,
        ),
        if (snap != null)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) => CustomPaint(
                    painter: _RevealPainter(
                      image: snap,
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

/// Paints the old-theme picture everywhere except inside the growing circle.
class _RevealPainter extends CustomPainter {
  final ui.Image image;
  final Offset origin;
  final double progress;

  const _RevealPainter({
    required this.image,
    required this.origin,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 1) return;
    final full = Offset.zero & size;
    final maxRadius = [
      (origin - full.topLeft).distance,
      (origin - full.topRight).distance,
      (origin - full.bottomLeft).distance,
      (origin - full.bottomRight).distance,
    ].reduce(math.max);

    // Even-odd fill = full rect minus the circle.
    final clip = Path()..fillType = PathFillType.evenOdd;
    clip.addRect(full);
    clip.addOval(Rect.fromCircle(center: origin, radius: maxRadius * progress));

    canvas.save();
    canvas.clipPath(clip);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      full,
      Paint()..filterQuality = FilterQuality.low,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RevealPainter old) =>
      old.progress != progress || old.image != image || old.origin != origin;
}
