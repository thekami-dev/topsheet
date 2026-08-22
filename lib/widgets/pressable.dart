import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../core/motion.dart';

/// Wraps [child] so it scales down the instant a finger touches it —
/// feedback on pointer-down, not on release — and springs back on lift.
/// Falls back to a plain 1:1 scale (no spring) under [MotionTier.reduced].
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
  });

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController.unbounded(vsync: this, value: 1);

  void _animateTo(double target) {
    final tier = motionTierOf(context);
    if (tier == MotionTier.reduced) {
      _controller.animateTo(target, duration: Motion.fast, curve: Curves.easeOut);
      return;
    }
    _controller.animateWith(
      SpringSimulation(appleSpring(damping: 1.0, response: 0.28), _controller.value, target, 0),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _animateTo(widget.pressedScale),
      onTapCancel: widget.onTap == null ? null : () => _animateTo(1),
      onTapUp: widget.onTap == null ? null : (_) => _animateTo(1),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(scale: _controller.value, child: child),
        child: widget.child,
      ),
    );
  }
}
